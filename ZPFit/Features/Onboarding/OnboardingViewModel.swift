import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    
    // Step 1: Email & Password
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isCheckingEmail = false
    @Published var emailAvailable: Bool? = nil // nil = not checked, true = available, false = taken
    @Published var emailCheckError: String?
    
    // Flag to track if user is already authenticated (has Firebase Auth account)
    let isExistingUser: Bool
    
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
    private var cancellables = Set<AnyCancellable>()
    private var emailCheckTask: Task<Void, Never>?
    
    init(authService: AuthenticationService, firestoreService: FirestoreService, prefilledEmail: String? = nil) {
        self.authService = authService
        self.firestoreService = firestoreService
        
        // If email is pre-filled, user is already authenticated
        if let email = prefilledEmail {
            self.isExistingUser = true
            self.email = email
            self.emailAvailable = true // Already authenticated, so email is "available" for this flow
            // Skip to name step since email/password are already set
            self.currentStep = 2
        } else {
            self.isExistingUser = false
        }
        
        // Only setup email validation for new users
        if !isExistingUser {
            setupEmailValidation()
        }
    }
    
    private func setupEmailValidation() {
        // Debounce email changes to avoid excessive API calls
        $email
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                guard let self = self else { return }
                
                // Reset state if email is empty or invalid
                guard !email.isEmpty, self.authService.isEmailValid(email) else {
                    self.emailAvailable = nil
                    self.emailCheckError = nil
                    return
                }
                
                // Check availability
                self.checkEmailAvailability()
            }
            .store(in: &cancellables)
    }
    
    func checkEmailAvailability() {
        // Cancel any pending check
        emailCheckTask?.cancel()
        
        guard authService.isEmailValid(email) else {
            emailAvailable = nil
            return
        }
        
        isCheckingEmail = true
        emailCheckError = nil
        emailAvailable = nil
        
        emailCheckTask = Task {
            let available = await authService.checkEmailAvailability(email)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isCheckingEmail = false
                self.emailAvailable = available
                
                if !available {
                    self.emailCheckError = "This email is already registered"
                } else {
                    self.emailCheckError = nil
                }
            }
        }
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
        // For existing users, email step is auto-valid (shouldn't be shown)
        if isExistingUser {
            return true
        }
        
        // For new users, validate everything
        return authService.isEmailValid(email) && 
            authService.isPasswordValid(password) && 
            password == confirmPassword &&
            emailAvailable == true && // Must be explicitly available
            !isCheckingEmail // Can't proceed while checking
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
            print("🚀 Starting onboarding completion...")
            
            // Get user ID (create account if new user, use existing if authenticated)
            let userId: String
            
            if isExistingUser {
                // User already has Firebase Auth account, just get their ID
                print("1️⃣ Using existing Firebase Auth account...")
                guard let existingUserId = authService.currentUserId else {
                    throw NSError(domain: "OnboardingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get existing user ID"])
                }
                userId = existingUserId
                print("2️⃣ Got existing user ID: \(userId)")
            } else {
                // New user - create Firebase Auth account
                print("1️⃣ Creating new Firebase Auth account...")
                try await authService.signUp(email: email, password: password, name: "\(firstName) \(lastName)")
                
                guard let newUserId = authService.currentUserId else {
                    throw NSError(domain: "OnboardingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID after signup"])
                }
                userId = newUserId
                print("2️⃣ Got new user ID: \(userId)")
            }
            
            // 3. Create complete user profile in Firestore
            print("3️⃣ Creating Firestore profile...")
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
            
            // 4. Reload user data to ensure isProfileComplete is set
            print("4️⃣ Reloading user data to verify profile...")
            await firestoreService.loadUserData(userId: userId)
            
            // Small delay to ensure Firestore write is complete and state is updated
            try await Task.sleep(for: .milliseconds(500))
            
            // 5. Verify profile is complete before proceeding
            guard firestoreService.isProfileComplete else {
                throw NSError(domain: "OnboardingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Profile creation failed - profile incomplete"])
            }
            print("5️⃣ Profile verified as complete")
            
            // 6. Mark onboarding as complete (this triggers ContentView navigation)
            await MainActor.run {
                print("6️⃣ Marking onboarding as complete")
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                isLoading = false
                print("✅ Onboarding completion successful!")
            }
            
        } catch {
            await MainActor.run {
                print("❌ Onboarding failed: \(error.localizedDescription)")
                isLoading = false
                errorMessage = authService.authError ?? error.localizedDescription
            }
        }
    }
}
