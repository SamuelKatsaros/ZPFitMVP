import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    
    // Step 1: Email & Password
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    // Step 2: Name
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    // Step 3: Date of Birth
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    
    // Step 4: Height
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 8
    
    // Step 5: Weight
    @Published var weightPounds: String = ""
    
    // Step 6: Experience Level
    @Published var selectedExperience: String = "Intermediate"
    
    // Step 7: Goals (multi-select)
    @Published var selectedGoals: Set<String> = []
    
    // State
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    let goalOptions = [
        "Build Muscle",
        "Lose Weight",
        "Get Toned",
        "General Fitness",
        "Athletic Performance"
    ]
    
    private let authService: AuthenticationService
    private let firestoreService: FirestoreService
    
    init(authService: AuthenticationService, firestoreService: FirestoreService) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    func previousStep() {
        withAnimation {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
    
    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    // Validation
    var isEmailStepValid: Bool {
        authService.isEmailValid(email) && 
        authService.isPasswordValid(password) && 
        password == confirmPassword
    }
    
    var isNameStepValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var isWeightStepValid: Bool {
        guard let weight = Int(weightPounds), weight > 0, weight < 1000 else {
            return false
        }
        return true
    }
    
    var isGoalsStepValid: Bool {
        !selectedGoals.isEmpty
    }
    
    func completeOnboarding() async {
        guard isGoalsStepValid else {
            errorMessage = "Please select at least one goal"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        do {
            // 1. Create Firebase Auth account
            try await authService.signUp(email: email, password: password, name: "\(firstName) \(lastName)")
            
            // 2. Get user ID
            guard let userId = authService.currentUserId else {
                throw NSError(domain: "OnboardingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])
            }
            
            // 3. Create complete user profile in Firestore
            let weight = Int(weightPounds) ?? 0
            try await firestoreService.createUserProfile(
                userId: userId,
                email: email,
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: dateOfBirth,
                heightFeet: heightFeet,
                heightInches: heightInches,
                weightPounds: weight,
                experienceLevel: selectedExperience,
                goals: Array(selectedGoals)
            )
            
            // 4. Mark onboarding as complete
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = authService.authError ?? error.localizedDescription
            }
        }
    }
}
