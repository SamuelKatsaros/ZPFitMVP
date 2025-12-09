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

/// ViewModel for managing run tracking state, timer, distance, and pace calculations
/// Uses miles for US locale (1 mile = 1609.344 meters)
@MainActor
class RunTrackingViewModel: ObservableObject {
    
    // MARK: - Constants
    
    private static let metersPerMile: Double = 1609.344
    private static let feetPerMeter: Double = 3.28084
    
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
        guard currentPace > 0 && currentPace.isFinite && currentPace < 3600 else {
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
    
    // Rolling pace calculation for smoother updates
    private var recentDistances: [Double] = []
    private var recentTimes: [TimeInterval] = []
    private let rollingWindowSize = 10
    
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
        recentDistances = []
        recentTimes = []
        
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
        
        // Record final partial split if we have any distance in current mile
        if currentSplitDistance > 0 {
            // Don't add partial splits to the splits array, but could calculate pace
        }
        
        runState = .finished
        locationService.stopTracking()
        stopTimer()
        
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
        guard runState == .running else { return }
        
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
            if altDiff > 0 {
                elevationGain += altDiff
            }
        }
        lastAltitude = altitudeFeet
        
        // Calculate distance from last location
        if let last = lastLocation {
            let additionalDistance = location.distance(from: last)
            
            // Filter out unrealistic jumps (>100m in a single update)
            if additionalDistance < 100 {
                distance += additionalDistance
                currentSplitDistance += additionalDistance
                
                // Check for mile split
                checkForMileSplit()
                
                // Update pace with rolling average
                updatePaceRolling(additionalDistance: additionalDistance)
            }
        }
        
        lastLocation = location
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
    
    private func updatePaceRolling(additionalDistance: Double) {
        recentDistances.append(additionalDistance)
        recentTimes.append(1.0) // Assuming ~1 second intervals
        
        // Keep window size limited
        while recentDistances.count > rollingWindowSize {
            recentDistances.removeFirst()
            recentTimes.removeFirst()
        }
        
        // Calculate rolling pace
        let totalRecentDistance = recentDistances.reduce(0, +)
        let totalRecentTime = recentTimes.reduce(0, +)
        
        guard totalRecentDistance > 0 else { return }
        
        // Seconds per mile
        let milesInWindow = totalRecentDistance / Self.metersPerMile
        currentPace = totalRecentTime / milesInWindow
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
        recentDistances = []
        recentTimes = []
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
