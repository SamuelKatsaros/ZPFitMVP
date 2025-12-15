import SwiftUI
import CoreLocation
import Combine

/// State of the run tracking session
enum RunState {
    case idle
    case running
    case paused
    case finished
}

/// Represents a location sample with timestamp for pace calculation
private struct LocationSample {
    let location: CLLocation
    let cumulativeDistance: Double // meters
    let timestamp: Date
}

/// ViewModel for managing run tracking state, timer, distance, and pace calculations
/// Uses miles for US locale (1 mile = 1609.344 meters)
/// Pace calculation uses actual GPS timestamps like Strava
@MainActor
class RunTrackingViewModel: ObservableObject {
    
    // MARK: - Constants
    
    private static let metersPerMile: Double = 1609.344
    private static let feetPerMeter: Double = 3.28084
    
    // Speed thresholds (meters per second)
    private static let stationarySpeedThreshold: Double = 0.3 // ~0.7 mph - below this = stationary
    private static let walkingSpeedMin: Double = 0.8 // ~1.8 mph - minimum for valid movement
    private static let maxRealisticSpeed: Double = 12.0 // ~27 mph - maximum realistic running speed
    
    // MARK: - Published Properties
    
    @Published var runState: RunState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0 // meters (internal)
    @Published var currentPace: Double = 0 // seconds per mile
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var errorMessage: String?
    
    // Enhanced tracking
    @Published var currentAltitude: Double = 0 // feet
    @Published var elevationGain: Double = 0 // feet
    @Published var splits: [Double] = [] // split times in seconds per mile
    @Published var currentSplitDistance: Double = 0 // meters into current mile
    @Published var currentSplitTime: TimeInterval = 0 // time for current mile
    @Published var isStationary: Bool = true // whether user is currently stationary
    
    // MARK: - Computed Properties (Display)
    
    var distanceMiles: Double {
        distance / Self.metersPerMile
    }
    
    var elapsedTimeFormatted: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var distanceFormatted: String {
        String(format: "%.2f", distanceMiles)
    }
    
    var paceFormatted: String {
        // Only show pace if we have enough distance and are moving
        guard currentPace > 0 && currentPace.isFinite && currentPace < 3600 else {
            return "--:--"
        }
        // Reasonable pace range: 4:00/mi (very fast) to 30:00/mi (slow walk)
        guard currentPace >= 240 && currentPace <= 1800 else {
            return "--:--"
        }
        let minutes = Int(currentPace) / 60
        let seconds = Int(currentPace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var elevationFormatted: String {
        String(format: "%.0f", elevationGain)
    }
    
    var currentMileNumber: Int {
        Int(distanceMiles) + 1
    }
    
    var currentSplitProgress: Double {
        currentSplitDistance / Self.metersPerMile
    }
    
    // MARK: - Dependencies
    
    private let locationService: LocationService
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?
    private var lastLocation: CLLocation?
    private var lastAltitude: Double?
    private var splitStartTime: TimeInterval = 0
    private var routePoints: [RoutePoint] = []
    private var cancellables = Set<AnyCancellable>()
    private var pendingStartRun = false
    
    // Pace calculation - store recent location samples with timestamps
    private var recentSamples: [LocationSample] = []
    private let paceWindowSeconds: TimeInterval = 30 // Calculate pace over last 30 seconds
    private var lastPaceUpdateTime: Date = Date()
    
    // Stationary detection
    private var stationaryLocationBuffer: [CLLocation] = []
    private let stationaryBufferSize = 5
    
    // MARK: - Initialization
    
    init(
        locationService: LocationService,
        firestoreService: FirestoreService,
        authService: AuthenticationService
    ) {
        self.locationService = locationService
        self.firestoreService = firestoreService
        self.authService = authService
        
        setupLocationSubscription()
        setupAuthorizationSubscription()
    }
    
    // MARK: - Public Methods
    
    /// Start a new run
    func startRun() {
        guard locationService.hasTrackingPermission else {
            print("📍 RunTrackingViewModel: Requesting permission, will start run when granted")
            pendingStartRun = true
            locationService.requestPermission()
            return
        }
        
        actuallyStartRun()
    }
    
    private func actuallyStartRun() {
        print("🏃 RunTrackingViewModel: Starting run")
        pendingStartRun = false
        
        // Reset state
        elapsedTime = 0
        distance = 0
        currentPace = 0
        routeCoordinates = []
        routePoints = []
        lastLocation = nil
        lastAltitude = nil
        pausedDuration = 0
        errorMessage = nil
        
        // Reset enhanced tracking
        currentAltitude = 0
        elevationGain = 0
        splits = []
        currentSplitDistance = 0
        currentSplitTime = 0
        splitStartTime = 0
        recentSamples = []
        stationaryLocationBuffer = []
        isStationary = true
        lastPaceUpdateTime = Date()
        
        // Start tracking
        startTime = Date()
        runState = .running
        locationService.startTracking()
        startTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    /// Pause the current run
    func pauseRun() {
        guard runState == .running else { return }
        
        print("⏸️ RunTrackingViewModel: Pausing run")
        runState = .paused
        pauseStartTime = Date()
        locationService.pauseTracking()
        stopTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Resume a paused run
    func resumeRun() {
        guard runState == .paused else { return }
        
        print("▶️ RunTrackingViewModel: Resuming run")
        
        // Calculate paused duration
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        
        // Clear samples buffer to get fresh pace after resume
        recentSamples = []
        lastLocation = nil
        
        runState = .running
        locationService.resumeTracking()
        startTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// End the current run
    func endRun() {
        guard runState == .running || runState == .paused else { return }
        
        print("🏁 RunTrackingViewModel: Ending run")
        
        // Handle case where we're paused
        if runState == .paused, let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        
        runState = .finished
        locationService.stopTracking()
        stopTimer()
        
        // Calculate final average pace
        currentPace = calculateAveragePace()
        
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Reset to idle state (discard run)
    func discardRun() {
        print("🗑️ RunTrackingViewModel: Discarding run")
        runState = .idle
        locationService.stopTracking()
        stopTimer()
        resetState()
    }
    
    /// Save the completed run to Firestore
    func saveRun() async -> Bool {
        print("💾 RunTrackingViewModel: saveRun() called")
        print("💾 Current runState: \(runState)")
        
        guard runState == .finished else {
            print("❌ saveRun: Run is not finished (state: \(runState))")
            return false
        }
        
        guard let userId = authService.currentUserId else {
            print("❌ saveRun: No user ID available")
            errorMessage = "Not logged in"
            return false
        }
        print("💾 User ID: \(userId)")
        
        guard let startTime = startTime else {
            print("❌ saveRun: No start time available")
            return false
        }
        
        let run = FirestoreRun(
            id: nil,
            distance: distance,
            duration: Int(elapsedTime),
            averagePace: calculateAveragePace(),
            startedAt: startTime,
            endedAt: Date(),
            route: routePoints,
            splits: splits.isEmpty ? nil : splits,
            elevationGain: elevationGain > 0 ? elevationGain : nil
        )
        
        print("💾 Saving run:")
        print("   - Distance: \(distance)m (\(run.distanceFormatted))")
        print("   - Duration: \(Int(elapsedTime))s (\(run.durationFormatted))")
        print("   - Pace: \(run.paceFormatted)")
        print("   - Route points: \(routePoints.count)")
        print("   - Splits: \(splits.count)")
        print("   - Elevation gain: \(elevationGain) ft")
        
        do {
            try await firestoreService.saveRun(userId: userId, run: run)
            print("✅ Run saved successfully to Firestore")
            return true
        } catch {
            print("❌ Failed to save run to Firestore: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            errorMessage = "Failed to save run: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationSubscription() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.processLocationUpdate(location)
            }
            .store(in: &cancellables)
        
        locationService.$locationError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthorizationSubscription() {
        locationService.$authorizationStatus
            .sink { [weak self] status in
                guard let self = self else { return }
                
                // If we were waiting for permission and now have it, start the run
                if self.pendingStartRun && 
                   (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    print("📍 RunTrackingViewModel: Permission granted, starting run")
                    self.actuallyStartRun()
                }
            }
            .store(in: &cancellables)
    }
    
    private func processLocationUpdate(_ location: CLLocation) {
        guard runState == .running else { 
            return 
        }
        
        let now = Date()
        
        // Use CLLocation's speed property if available and valid
        let gpsSpeed = location.speed >= 0 ? location.speed : 0
        print("🏃 Location update: speed=\(String(format: "%.2f", gpsSpeed))m/s, accuracy=\(String(format: "%.1f", location.horizontalAccuracy))m")
        
        // Determine if user is stationary using GPS speed
        let wasStationary = isStationary
        isStationary = gpsSpeed < Self.stationarySpeedThreshold
        
        if isStationary {
            print("   🧍 User is stationary (speed < \(Self.stationarySpeedThreshold)m/s)")
            // Don't add to route when stationary to avoid GPS drift
            // But still update the last location for when movement resumes
            stationaryLocationBuffer.append(location)
            if stationaryLocationBuffer.count > stationaryBufferSize {
                stationaryLocationBuffer.removeFirst()
            }
            
            // Show "--:--" pace when stationary
            if wasStationary != isStationary {
                // Just became stationary - keep last known pace for a moment
                print("   ⏸️ Movement stopped")
            }
            return
        }
        
        // User is moving - process the location
        print("   🏃‍♂️ User is moving")
        
        // If we just started moving, use the average of stationary buffer as reference
        if wasStationary && !isStationary && !stationaryLocationBuffer.isEmpty {
            lastLocation = stationaryLocationBuffer.last
            stationaryLocationBuffer.removeAll()
            print("   ▶️ Movement resumed from stationary")
        }
        
        // Add to route
        let coordinate = location.coordinate
        routeCoordinates.append(coordinate)
        
        let routePoint = RoutePoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: location.timestamp,
            altitude: location.altitude
        )
        routePoints.append(routePoint)
        
        // Update altitude (convert to feet)
        let altitudeFeet = location.altitude * Self.feetPerMeter
        currentAltitude = altitudeFeet
        
        // Calculate elevation gain
        if let lastAlt = lastAltitude {
            let altDiff = altitudeFeet - lastAlt
            if altDiff > 3 { // Only count gains > 3 feet to filter noise
                elevationGain += altDiff
            }
        }
        lastAltitude = altitudeFeet
        
        // Calculate distance from last location
        if let last = lastLocation {
            let additionalDistance = location.distance(from: last)
            let timeSinceLast = location.timestamp.timeIntervalSince(last.timestamp)
            
            // Calculate instantaneous speed from distance/time
            let calculatedSpeed = timeSinceLast > 0 ? additionalDistance / timeSinceLast : 0
            
            print("   📏 Distance: \(String(format: "%.2f", additionalDistance))m in \(String(format: "%.1f", timeSinceLast))s")
            print("   🚀 Calculated speed: \(String(format: "%.2f", calculatedSpeed))m/s (\(String(format: "%.1f", calculatedSpeed * 2.237))mph)")
            
            // Filter: accept if calculated speed is reasonable for running/walking
            let isReasonableSpeed = calculatedSpeed >= Self.stationarySpeedThreshold && 
                                   calculatedSpeed <= Self.maxRealisticSpeed
            let isReasonableDistance = additionalDistance >= 1.0 && additionalDistance < 200 // 1-200m
            
            if isReasonableSpeed && isReasonableDistance {
                distance += additionalDistance
                currentSplitDistance += additionalDistance
                
                print("   ✅ Distance added! Total: \(String(format: "%.0f", distance))m (\(distanceFormatted) mi)")
                
                // Add sample for pace calculation (using actual timestamps!)
                let sample = LocationSample(
                    location: location,
                    cumulativeDistance: distance,
                    timestamp: location.timestamp
                )
                recentSamples.append(sample)
                
                // Check for mile split
                checkForMileSplit()
                
                // Update pace using actual timestamps
                updatePaceFromSamples()
            } else {
                print("   ⚠️ Filtered: speed=\(String(format: "%.2f", calculatedSpeed))m/s, distance=\(String(format: "%.1f", additionalDistance))m")
            }
        } else {
            print("   ℹ️ First location recorded")
        }
        
        lastLocation = location
    }
    
    private func updatePaceFromSamples() {
        // Remove samples older than our window
        let windowStart = Date().addingTimeInterval(-paceWindowSeconds)
        recentSamples = recentSamples.filter { $0.timestamp > windowStart }
        
        // Need at least 2 samples to calculate pace
        guard recentSamples.count >= 2,
              let oldest = recentSamples.first,
              let newest = recentSamples.last else {
            print("   ⏱️ Not enough samples for pace (\(recentSamples.count) samples)")
            return
        }
        
        // Calculate pace from actual distance traveled and actual time elapsed
        let windowDistance = newest.cumulativeDistance - oldest.cumulativeDistance
        let windowTime = newest.timestamp.timeIntervalSince(oldest.timestamp)
        
        guard windowDistance > 0 && windowTime > 3 else {
            print("   ⏱️ Window too small: \(String(format: "%.1f", windowDistance))m in \(String(format: "%.1f", windowTime))s")
            return
        }
        
        // Calculate seconds per mile
        let milesInWindow = windowDistance / Self.metersPerMile
        let secondsPerMile = windowTime / milesInWindow
        
        // Sanity check: pace should be between 4:00/mi and 30:00/mi
        if secondsPerMile >= 240 && secondsPerMile <= 1800 {
            // Smooth the pace update
            if currentPace > 0 {
                currentPace = currentPace * 0.7 + secondsPerMile * 0.3 // Weighted average
            } else {
                currentPace = secondsPerMile
            }
            print("   ⏱️ Pace: \(paceFormatted)/mi (window: \(String(format: "%.0f", windowDistance))m in \(String(format: "%.0f", windowTime))s)")
        } else {
            print("   ⚠️ Pace out of range: \(String(format: "%.0f", secondsPerMile))s/mi")
        }
    }
    
    private func checkForMileSplit() {
        let milesCompleted = Int(distance / Self.metersPerMile)
        
        if milesCompleted > splits.count {
            // Completed a new mile
            let splitTime = elapsedTime - splitStartTime
            splits.append(splitTime)
            
            print("🏃 Mile \(milesCompleted) completed: \(formatTime(splitTime))")
            
            // Reset for next mile
            currentSplitDistance = distance - (Double(milesCompleted) * Self.metersPerMile)
            splitStartTime = elapsedTime
            
            // Haptic feedback for milestone
            let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
            impactFeedback.impactOccurred()
        }
    }
    
    private func calculateAveragePace() -> Double {
        // Returns seconds per mile
        guard distance > 0 && elapsedTime > 0 else { return 0 }
        let miles = distance / Self.metersPerMile
        return elapsedTime / miles
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard let start = startTime, runState == .running else { return }
        elapsedTime = Date().timeIntervalSince(start) - pausedDuration
        currentSplitTime = elapsedTime - splitStartTime
    }
    
    private func resetState() {
        elapsedTime = 0
        distance = 0
        currentPace = 0
        routeCoordinates = []
        routePoints = []
        lastLocation = nil
        lastAltitude = nil
        startTime = nil
        pausedDuration = 0
        pauseStartTime = nil
        errorMessage = nil
        currentAltitude = 0
        elevationGain = 0
        splits = []
        currentSplitDistance = 0
        currentSplitTime = 0
        splitStartTime = 0
        recentSamples = []
        stationaryLocationBuffer = []
        isStationary = true
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
