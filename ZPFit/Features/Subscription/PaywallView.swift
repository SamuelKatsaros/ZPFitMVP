import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background Image
            Image(systemName: "figure.strengthtraining.traditional") // Placeholder
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(Color.white.opacity(0.95))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("UNLOCK YOUR POTENTIAL")
                    .font(.ZP.display)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.black)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(text: "Unlimited Access to All Programs")
                    FeatureRow(text: "Exclusive Cardio & HIIT Sessions")
                    FeatureRow(text: "Advanced Progress Tracking")
                    FeatureRow(text: "Direct Support from Zach")
                }
                .padding()
                
                Spacer()
                
                // Pricing Cards
                HStack(spacing: 16) {
                    PricingCard(title: "Monthly", price: "$14.99", period: "/mo", action: {
                        Task { await subscriptionService.purchase(productId: "monthly") }
                    })
                    
                    PricingCard(title: "Annual", price: "$119.99", period: "/yr", isBestValue: true, action: {
                        Task { await subscriptionService.purchase(productId: "annual") }
                    })
                }
                .padding(.horizontal)
                
                Button("Restore Purchases") {
                    Task { await subscriptionService.restore() }
                }
                .font(.ZP.caption)
                .foregroundStyle(Color.gray)
                .padding(.bottom)
            }
        }
        .onChange(of: subscriptionService.isPremium) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

struct FeatureRow: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.ZP.accent)
            Text(text)
                .font(.ZP.body)
                .foregroundStyle(Color.black)
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    var isBestValue: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if isBestValue {
                    Text("BEST VALUE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(Color.ZP.accent)
                        .foregroundStyle(Color.ZP.textBlack)
                        .cornerRadius(4)
                }
                
                Text(title)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.gray)
                
                Text(price)
                    .font(.ZP.title1)
                    .foregroundStyle(Color.black)
                
                Text(period)
                    .font(.ZP.caption)
                    .foregroundStyle(Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isBestValue ? Color.ZP.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}
