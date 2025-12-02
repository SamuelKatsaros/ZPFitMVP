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
            
            VStack {
                // Progress Indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= viewModel.currentStep ? Color.ZP.primary : Color.ZP.card)
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Steps
                Group {
                    if viewModel.currentStep == 0 {
                        WelcomeStep(action: viewModel.nextStep)
                    } else if viewModel.currentStep == 1 {
                        NameStep(name: $viewModel.name, action: viewModel.nextStep)
                    } else if viewModel.currentStep == 2 {
                        SelectionStep(
                            title: "Experience Level",
                            options: viewModel.experienceLevels,
                            selection: $viewModel.selectedExperience,
                            action: viewModel.completeOnboarding
                        )
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
                Spacer()
            }
        }
    }
}

// MARK: - Steps

struct WelcomeStep: View {
    var action: () -> Void
    
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
            
            Button(action: action) {
                Text("Get Started")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ZP.primary)
                    .foregroundStyle(Color.ZP.textBlack)
                    .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct NameStep: View {
    @Binding var name: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            TextField("Your Name", text: $name)
                .font(.ZP.title2)
                .padding()
                .background(Color.ZP.card)
                .cornerRadius(12)
                .foregroundStyle(Color.ZP.textPrimary)
                .padding(.horizontal, 40)
            
            Button(action: action) {
                Text("Next")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.ZP.cardHover : Color.ZP.primary)
                    .foregroundStyle(name.isEmpty ? Color.ZP.textSecondary : Color.ZP.textBlack)
                    .cornerRadius(12)
            }
            .disabled(name.isEmpty)
            .padding(.horizontal, 40)
        }
    }
}

struct SelectionStep: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    HStack {
                        Text(option)
                            .font(.ZP.body)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.ZP.primary)
                        }
                    }
                    .padding()
                    .background(selection == option ? Color.ZP.cardHover : Color.ZP.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == option ? Color.ZP.primary : Color.clear, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
            }
            
            Spacer().frame(height: 20)
            
            Button(action: action) {
                Text("Continue")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ZP.primary)
                    .foregroundStyle(Color.ZP.textBlack)
                    .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}
