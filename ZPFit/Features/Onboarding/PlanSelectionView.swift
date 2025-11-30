import SwiftUI

struct PlanSelectionView: View {
    @AppStorage("selectedPlan") private var selectedPlan: String?
    @Environment(\.dismiss) private var dismiss
    
    let plans = [
        PlanOption(id: "lose_weight", title: "Lose Weight", subtitle: "Burn fat & get lean", icon: "flame.fill"),
        PlanOption(id: "build_muscle", title: "Build Muscle", subtitle: "Hypertrophy & Strength", icon: "dumbbell.fill"),
        PlanOption(id: "get_stronger", title: "Get Stronger", subtitle: "Power & Performance", icon: "figure.strengthtraining.traditional")
    ]
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Choose Your Goal")
                        .font(.ZP.display)
                        .foregroundStyle(Color.ZP.textPrimary)
                    
                    Text("We'll tailor your experience based on your selection.")
                        .font(.ZP.body)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    ForEach(plans) { plan in
                        PlanOptionCard(plan: plan, isSelected: selectedPlan == plan.id) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlan = plan.id
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    if selectedPlan != nil {
                        dismiss()
                    }
                }) {
                    Text("Continue")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textBlack)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPlan != nil ? Color.ZP.primary : Color.ZP.cardHover)
                        .cornerRadius(16)
                }
                .disabled(selectedPlan == nil)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct PlanOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
}

struct PlanOptionCard: View {
    let plan: PlanOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.ZP.primary : Color.ZP.cardHover)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: plan.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.ZP.textBlack : Color.ZP.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textPrimary)
                    
                    Text(plan.subtitle)
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.ZP.primary)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            .padding()
            .background(Color.ZP.card)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.ZP.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}
