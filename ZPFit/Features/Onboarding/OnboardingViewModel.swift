import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var name: String = ""
    @Published var selectedGoal: String = "General Fitness"
    @Published var selectedExperience: String = "Intermediate"
    
    let goals = ["Fat Loss", "Muscle Build", "Athletic Performance", "General Fitness"]
    let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    
    private let userProfileService: UserProfileService
    
    init(userProfileService: UserProfileService) {
        self.userProfileService = userProfileService
    }
    
    func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    func completeOnboarding() {
        userProfileService.createOrUpdateUser(
            name: name,
            goal: selectedGoal,
            experience: selectedExperience
        )
        userProfileService.completeOnboarding()
    }
}
