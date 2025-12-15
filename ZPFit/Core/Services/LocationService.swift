import Foundation
import CoreLocation
import Combine

/// Service responsible for GPS location tracking during runs.
/// Handles location permissions, continuous updates, and background tracking.
@MainActor
class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var locationError: String?
    
    // MARK: - Private Properties
    
    private let locationManager: CLLocationManager
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?
    
    // MARK: - Initialization
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // meters - balance between accuracy and battery
        locationManager.activityType = .fitness
        // Note: allowsBackgroundLocationUpdates is set in startTracking() after confirming
        // the app has the background location capability enabled
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Get initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Request location permission from the user
    func requestPermission() {
        print("📍 LocationService: Requesting location permission")
        print("📍 LocationService: Location services enabled: \(CLLocationManager.locationServicesEnabled())")
        print("📍 LocationService: Current authorization: \(authorizationStatus.rawValue)")
        
        if !CLLocationManager.locationServicesEnabled() {
            print("❌ LocationService: Location services are disabled system-wide")
            locationError = "Location services are disabled. Enable in Settings."
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        print("📍 LocationService: requestWhenInUseAuthorization() called")
    }
    
    /// Request always authorization for background tracking
    func requestAlwaysPermission() {
        print("📍 LocationService: Requesting always authorization")
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Start continuous location tracking for a run
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ LocationService: Cannot start tracking - not authorized")
            locationError = "Location permission required"
            return
        }
        
        print("🏃 LocationService: Starting location tracking")
        isTracking = true
        locationError = nil
        
        // Enable background updates if the app has the capability
        // This will only work if UIBackgroundModes includes "location" in Info.plist
        if authorizationStatus == .authorizedAlways {
            // Only set this if we have Always authorization
            // The app must also have Background Modes -> Location enabled in Xcode
            if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
                locationManager.allowsBackgroundLocationUpdates = true
                print("📍 LocationService: Background location updates enabled")
            }
        }
        
        locationManager.startUpdatingLocation()
    }
    
    /// Stop location tracking
    func stopTracking() {
        print("🛑 LocationService: Stopping location tracking")
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Pause location tracking (keeps manager configured but stops updates)
    func pauseTracking() {
        print("⏸️ LocationService: Pausing location tracking")
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Resume location tracking after pause
    func resumeTracking() {
        print("▶️ LocationService: Resuming location tracking")
        isTracking = true
        locationManager.startUpdatingLocation()
    }
    
    /// Check if location services are available on device
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Check if we have sufficient authorization for tracking
    var hasTrackingPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out invalid locations (negative accuracy means invalid)
        guard location.horizontalAccuracy >= 0 else {
            print("📍 LocationService: Filtered out invalid location (negative accuracy)")
            return
        }
        
        // Accept locations with < 100m accuracy (outdoor GPS is often 50-100m)
        guard location.horizontalAccuracy < 100 else {
            print("📍 LocationService: Filtered out low-accuracy location (\(location.horizontalAccuracy)m)")
            return
        }
        
        // Filter stale cached locations (older than 10 seconds)
        guard abs(location.timestamp.timeIntervalSinceNow) < 10 else {
            print("📍 LocationService: Filtered out stale location (age: \(abs(location.timestamp.timeIntervalSinceNow))s)")
            return
        }
        
        print("📍 LocationService: ✅ Accepting location (accuracy: \(String(format: "%.1f", location.horizontalAccuracy))m, age: \(String(format: "%.1f", abs(location.timestamp.timeIntervalSinceNow)))s)")
        
        Task { @MainActor in
            self.currentLocation = location
            print("📍 LocationService: Updated location - lat: \(location.coordinate.latitude), lng: \(location.coordinate.longitude)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationService: Location error - \(error.localizedDescription)")
        
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied. Please enable in Settings."
                case .locationUnknown:
                    self.locationError = "Unable to determine location. Please try again."
                default:
                    self.locationError = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.locationError = error.localizedDescription
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 LocationService: Authorization changed to \(status.rawValue)")
        
        Task { @MainActor in
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
            case .denied, .restricted:
                self.locationError = "Location access denied. Please enable in Settings."
                self.isTracking = false
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
