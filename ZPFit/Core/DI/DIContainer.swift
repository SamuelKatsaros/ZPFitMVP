import SwiftUI
import SwiftData
import Combine

@MainActor
class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    // Services
    let persistenceService: PersistenceService
    let userProfileService: UserProfileService
    let subscriptionService: SubscriptionService
    
    init() {
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
