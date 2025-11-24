import Foundation
import SwiftData
import Combine
import SwiftUI

@MainActor
class UserProfileService: ObservableObject {
    private let modelContainer: ModelContainer
    private let context: ModelContext
    
    @Published var currentUser: UserProfile?
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.context = modelContainer.mainContext
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let users = try context.fetch(descriptor)
            self.currentUser = users.first
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
    
    func createOrUpdateUser(name: String, goal: String, experience: String) {
        if let user = currentUser {
            user.name = name
            user.goal = goal
            user.experienceLevel = experience
        } else {
            let newUser = UserProfile(name: name, experienceLevel: experience, goal: goal)
            context.insert(newUser)
            self.currentUser = newUser
        }
        
        save()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
