import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    private let firestoreService: FirestoreService
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                print("🔐 Auth state changed. User: \(user?.uid ?? "nil")")
                
                // Load user data when authenticated
                if let userId = user?.uid {
                    await self?.firestoreService.loadUserData(userId: userId)
                    
                    // NOTE: We allow users with incomplete profiles to remain authenticated
                    // ContentView will route them to onboarding to complete their profile
                    // This handles the edge case where users create an account but exit before completing onboarding
                }
                
                // NOTE: Sessions are now loaded in MainTabView to avoid loading during onboarding
                // This significantly improves performance during signup flow
            }
        }
    }
    
    var currentUserId: String? {
        currentUser?.uid
    }
    
    var currentUserEmail: String? {
        currentUser?.email
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, name: String? = nil) async throws {
        authError = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name if provided
            if let name = name {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }
            
            currentUser = result.user
            isAuthenticated = true
            
        } catch {
            authError = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) async throws {
        authError = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            
        } catch {
            authError = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            authError = nil
            firestoreService.clearUserData()
            
            // Clear onboarding flag to force re-authentication
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        } catch {
            authError = "Failed to sign out: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        authError = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            authError = handleAuthError(error)
            throw error
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        
        // Check if this is a Firebase Auth error
        guard nsError.domain == AuthErrorDomain else {
            return "An unknown error occurred: \(error.localizedDescription)"
        }
        
        // Convert to AuthErrorCode
        guard let errorCode = AuthErrorCode(_bridgedNSError: nsError) else {
            return "An unknown error occurred: \(error.localizedDescription)"
        }
        
        switch errorCode.code {
        case .invalidEmail:
            return "Invalid email address format."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .wrongPassword:
            return "Incorrect password."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled."
        default:
            return "Authentication error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Email Availability
    
    /// Check if an email is already registered
    /// Returns true if email is available (not registered), false if already in use
    func checkEmailAvailability(_ email: String) async -> Bool {
        // First validate email format
        guard isEmailValid(email) else {
            return true // Invalid emails are "available" (won't show "already registered")
        }
        
        do {
            // Attempt to sign in with a dummy password
            // This will fail, but the error code tells us if the email exists
            _ = try await Auth.auth().signIn(withEmail: email, password: "dummy_password_check_\(UUID().uuidString)")
            
            // If sign-in somehow succeeds (shouldn't happen), email exists
            return false
            
        } catch {
            let nsError = error as NSError
            
            // Check if this is a Firebase Auth error
            guard nsError.domain == AuthErrorDomain,
                  let errorCode = AuthErrorCode(_bridgedNSError: nsError) else {
                // Network error or other issue - assume available to avoid blocking users
                print("⚠️ Non-Auth error during email check: \(error.localizedDescription)")
                return true
            }
            
            switch errorCode.code {
            case .userNotFound:
                // Email doesn't exist - available!
                return true
                
            case .wrongPassword:
                // Email exists but password was wrong - unavailable
                return false
                
            case .invalidEmail:
                // Invalid email format - treat as available
                return true
                
            default:
                // Other errors (network, etc.) - assume available to avoid false positives
                print("⚠️ Unknown auth error during email check: \(errorCode.code)")
                return true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func isEmailValid(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isPasswordValid(_ password: String) -> Bool {
        return password.count >= 6
    }
}
