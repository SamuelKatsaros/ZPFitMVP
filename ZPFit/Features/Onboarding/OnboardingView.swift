import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.diContainer) private var diContainer
    
    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicator
                HStack(spacing: 4) {
                    ForEach(0..<8) { index in
                        Capsule()
                            .fill(index <= viewModel.currentStep ? Color.ZP.primary : Color.ZP.card)
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        Group {
                            switch viewModel.currentStep {
                            case 0:
                                WelcomeStep(action: viewModel.nextStep)
                            case 1:
                                // Skip email/password for existing users, show name instead
                                if viewModel.isExistingUser {
                                    NameStep(viewModel: viewModel)
                                } else {
                                    EmailPasswordStep(viewModel: viewModel)
                                }
                            case 2:
                                NameStep(viewModel: viewModel)
                            case 3:
                                DateOfBirthStep(viewModel: viewModel)
                            case 4:
                                HeightStep(viewModel: viewModel)
                            case 5:
                                WeightStep(viewModel: viewModel)
                            case 6:
                                ExperienceStep(viewModel: viewModel)
                            case 7:
                                GoalsStep(viewModel: viewModel)
                            default:
                                WelcomeStep(action: viewModel.nextStep)
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                    .padding(.vertical, 40)
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.error)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Step 0: Welcome
struct WelcomeStep: View {
    var action: () -> Void
    @State private var showLogin = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(Color.ZP.primary)
                .padding(.bottom, 20)
            
            Text("Welcome to ZP Fit")
                .font(.ZP.display)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Text("Your personal path to peak performance with Zach Powell.")
                .font(.ZP.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ZP.textSecondary)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 40)
            
            // Get Started (Sign Up)
            Button(action: action) {
                Text("Get Started")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ZP.primary)
                    .foregroundStyle(Color.ZP.textBlack)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Sign In
            Button(action: { showLogin = true }) {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(Color.ZP.textSecondary)
                    Text("Sign In")
                        .foregroundStyle(Color.ZP.primary)
                }
                .font(.ZP.subheadline)
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}

// MARK: - Step 1: Email & Password
struct EmailPasswordStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Your Account")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Text("Sign up to get started with ZP Fit")
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
            
            VStack(spacing: 16) {
                // Email field with validation feedback
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            textContentType: .emailAddress,
                            focusedField: $focusedField,
                            field: .email,
                            submitLabel: .next,
                            onSubmit: { focusedField = .password }
                        )
                        
                        // Email availability indicator
                        if viewModel.isCheckingEmail {
                            ProgressView()
                                .tint(Color.ZP.primary)
                                .padding(.trailing, 8)
                        } else if let available = viewModel.emailAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(available ? Color.green : Color.ZP.error)
                                .font(.title3)
                                .padding(.trailing, 8)
                        }
                    }
                    
                    // Email error message
                    if let error = viewModel.emailCheckError {
                        Text(error)
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.error)
                            .padding(.leading, 4)
                    }
                }
                
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Password (min 6 characters)",
                    text: $viewModel.password,
                    isSecure: true,
                    textContentType: .newPassword,
                    focusedField: $focusedField,
                    field: .password,
                    submitLabel: .next,
                    onSubmit: { focusedField = .confirmPassword }
                )
                
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    isSecure: true,
                    textContentType: .newPassword,
                    focusedField: $focusedField,
                    field: .confirmPassword,
                    submitLabel: .go,
                    onSubmit: viewModel.nextStep
                )
            }
            .padding(.horizontal, 40)
            
            Button(action: viewModel.nextStep) {
                Text("Next")
                .font(.ZP.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isEmailStepValid ? Color.ZP.primary : Color.ZP.cardHover)
                .foregroundStyle(viewModel.isEmailStepValid ? Color.ZP.textBlack : Color.ZP.textSecondary)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isEmailStepValid)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 2: Name
struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            VStack(spacing: 16) {
                TextField("First Name", text: $viewModel.firstName)
                    .font(.ZP.body)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                TextField("Last Name", text: $viewModel.lastName)
                    .font(.ZP.body)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                    .foregroundStyle(Color.ZP.textPrimary)
            }
            .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: viewModel.nextStep) {
                    Text("Next")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isNameStepValid ? Color.ZP.primary : Color.ZP.cardHover)
                        .foregroundStyle(viewModel.isNameStepValid ? Color.ZP.textBlack : Color.ZP.textSecondary)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isNameStepValid)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 3: Date of Birth
struct DateOfBirthStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("When's your birthday?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            DatePicker("", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: viewModel.nextStep) {
                    Text("Next")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.primary)
                        .foregroundStyle(Color.ZP.textBlack)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 4: Height
struct HeightStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How tall are you?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Feet")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textSecondary)
                    Picker("Feet", selection: $viewModel.heightFeet) {
                        ForEach(3..<8) { feet in
                            Text("\(feet)").tag(feet)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
                
                VStack {
                    Text("Inches")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textSecondary)
                    Picker("Inches", selection: $viewModel.heightInches) {
                        ForEach(0..<12) { inches in
                            Text("\(inches)").tag(inches)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
            }
            .padding()
            .background(Color.ZP.card)
            .cornerRadius(16)
            .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: viewModel.nextStep) {
                    Text("Next")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.primary)
                        .foregroundStyle(Color.ZP.textBlack)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 5: Weight
struct WeightStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your weight?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            HStack {
                TextField("Weight", text: $viewModel.weightPounds)
                    .font(.ZP.title2)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("lbs")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: viewModel.nextStep) {
                    Text("Next")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isWeightStepValid ? Color.ZP.primary : Color.ZP.cardHover)
                        .foregroundStyle(viewModel.isWeightStepValid ? Color.ZP.textBlack : Color.ZP.textSecondary)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isWeightStepValid)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 6: Experience Level
struct ExperienceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Experience Level")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            ForEach(viewModel.experienceLevels, id: \.self) { level in
                Button(action: { viewModel.selectedExperience = level }) {
                    HStack {
                        Text(level)
                            .font(.ZP.body)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        if viewModel.selectedExperience == level {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.ZP.primary)
                        }
                    }
                    .padding()
                    .background(viewModel.selectedExperience == level ? Color.ZP.cardHover : Color.ZP.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedExperience == level ? Color.ZP.primary : Color.clear, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: viewModel.nextStep) {
                    Text("Next")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.primary)
                        .foregroundStyle(Color.ZP.textBlack)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Step 7: Goals
struct GoalsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What are your goals?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Text("Select all that apply")
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
            
            ForEach(viewModel.goalOptions, id: \.self) { goal in
                Button(action: { viewModel.toggleGoal(goal) }) {
                    HStack {
                        Text(goal)
                            .font(.ZP.body)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        if viewModel.selectedGoals.contains(goal) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.ZP.primary)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                    }
                    .padding()
                    .background(viewModel.selectedGoals.contains(goal) ? Color.ZP.cardHover : Color.ZP.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedGoals.contains(goal) ? Color.ZP.primary : Color.clear, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 12) {
                Button(action: viewModel.previousStep) {
                    Text("Back")
                        .font(.ZP.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.card)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                }) {
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Complete")
                                .font(.ZP.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isGoalsStepValid ? Color.ZP.primary : Color.ZP.cardHover)
                    .foregroundStyle(viewModel.isGoalsStepValid ? Color.ZP.textBlack : Color.ZP.textSecondary)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isGoalsStepValid || viewModel.isLoading)
            }
            .padding(.horizontal, 40)
        }
    }
}
