import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo/Header
                    VStack(spacing: 12) {
                        Text("ZP Fit")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.ZP.title3)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            // Name Field
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: "Full Name",
                                text: $name,
                                focusedField: $focusedField,
                                field: .name,
                                submitLabel: .next,
                                onSubmit: { focusedField = .email }
                            )
                        }
                        
                        // Email Field
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
                        
                        // Password Field
                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            textContentType: isSignUp ? .newPassword : .password,
                            focusedField: $focusedField,
                            field: .password,
                            submitLabel: isSignUp ? .next : .done,
                            onSubmit: {
                                if isSignUp {
                                    focusedField = .confirmPassword
                                } else {
                                    handleSubmit()
                                }
                            }
                        )
                        
                        if isSignUp {
                            // Confirm Password Field
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                isSecure: true,
                                textContentType: .newPassword,
                                focusedField: $focusedField,
                                field: .confirmPassword,
                                submitLabel: .done,
                                onSubmit: handleSubmit
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.error)
                            .padding(.horizontal, 20)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Sign Up" : "Log In")
                                    .font(.ZP.headline)
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    
                    // Toggle Sign Up/Login
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            clearForm()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(Color.ZP.textSecondary)
                            Text(isSignUp ? "Log In" : "Sign Up")
                                .foregroundStyle(Color.blue)
                                .fontWeight(.semibold)
                        }
                        .font(.ZP.subheadline)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        // Email validation
        guard authService.isEmailValid(email) else { return false }
        
        // Password validation
        guard authService.isPasswordValid(password) else { return false }
        
        // Sign up specific validation
        if isSignUp {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
            guard password == confirmPassword else { return false }
        }
        
        return true
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        hideKeyboard()
        showError = false
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password, name: name)
                    // Create user profile in Firestore (legacy - minimal data)
                    if let userId = authService.currentUserId {
                        // Split name into first/last if possible
                        let nameParts = name.split(separator: " ")
                        let firstName = nameParts.first.map(String.init)
                        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : nil
                        
                        try await DIContainer.shared.firestoreService.createUserProfile(
                            userId: userId,
                            email: email,
                            firstName: firstName,
                            lastName: lastName,
                            dateOfBirth: nil,
                            heightFeet: nil,
                            heightInches: nil,
                            weightPounds: nil,
                            experienceLevel: nil,
                            goals: nil
                        )
                    }
                } else {
                    try await authService.login(email: email, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
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
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        showError = false
        errorMessage = ""
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom TextField

struct CustomTextField<FocusField: Hashable>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure: Bool = false
    var textContentType: UITextContentType?
    var focusedField: FocusState<FocusField?>.Binding
    var field: FocusField?
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(Color.ZP.textSecondary)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.ZP.body)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .textInputAutocapitalization(autocapitalization)
                    .textContentType(textContentType)
                    .focused(focusedField, equals: field)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .font(.ZP.body)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .textContentType(textContentType)
                    .focused(focusedField, equals: field)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .autocorrectionDisabled()
            }
        }
        .padding(20)
        .background(Color.ZP.card)
        .cornerRadius(16)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(DIContainer.shared.authenticationService)
}
