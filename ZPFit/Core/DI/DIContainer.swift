import SwiftUI
import SwiftData
import Combine
import FirebaseCore

@MainActor
class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    // Legacy SwiftData Services (keeping for backward compatibility during transition)
    let persistenceService: PersistenceService
    let userProfileService: UserProfileService
    let subscriptionService: SubscriptionService
    
    // Firebase Services
    let authenticationService: AuthenticationService
    let firestoreService: FirestoreService
    let cloudflareStreamService: CloudflareStreamService
    
    // Location Services
    let locationService: LocationService
    
    init() {
        // Ensure Firebase is configured before initializing any Firebase services
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Initialize Firebase services - order matters for dependencies
        self.firestoreService = FirestoreService()
        self.authenticationService = AuthenticationService(firestoreService: firestoreService)
        self.cloudflareStreamService = CloudflareStreamService()
        
        // Initialize location services
        self.locationService = LocationService()
        
        // Initialize legacy services (for gradual migration)
        self.persistenceService = PersistenceService()
        self.userProfileService = UserProfileService(modelContainer: persistenceService.container)
        self.subscriptionService = SubscriptionService()
    }
}

// Environment Key for DIContainer
struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
