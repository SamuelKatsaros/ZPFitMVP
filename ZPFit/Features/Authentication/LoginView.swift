import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email
        case password
    }
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.ZP.display)
                        .foregroundStyle(Color.ZP.textPrimary)
                    
                    Text("Sign in to continue your fitness journey")
                        .font(.ZP.body)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        textContentType: .emailAddress,
                        focusedField: $focusedField,
                        field: .email,
                        submitLabel: .next,
                        onSubmit: { focusedField = .password }
                    )
                    
                    CustomTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password,
                        focusedField: $focusedField,
                        field: .password,
                        submitLabel: .go,
                        onSubmit: handleLogin
                    )
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if showError {
                    Text(errorMessage)
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Login Button
                Button(action: handleLogin) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Sign In")
                                .font(.ZP.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.ZP.primary : Color.ZP.cardHover)
                    .foregroundStyle(isFormValid ? Color.ZP.textBlack : Color.ZP.textSecondary)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Back to Sign Up
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(Color.ZP.textSecondary)
                        Text("Sign Up")
                            .foregroundStyle(Color.ZP.primary)
                    }
                    .font(.ZP.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var isFormValid: Bool {
        authService.isEmailValid(email) && !password.isEmpty
    }
    
    private func handleLogin() {
        hideKeyboard()
        showError = false
        isLoading = true
        
        Task {
            do {
                try await authService.login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = authService.authError ?? error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
