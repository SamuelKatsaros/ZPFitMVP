import SwiftUI

struct CoachView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero Image
                        Rectangle()
                            .fill(Color.ZP.card)
                            .frame(height: 350)
                            .overlay(
                                ZStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 100))
                                        .foregroundStyle(Color.ZP.textSecondary.opacity(0.3))
                                    
                                    LinearGradient(
                                        colors: [.clear, Color.ZP.background],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            )
                        
                        VStack(alignment: .leading, spacing: 24) {
                            // Name & Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Zach Powell")
                                    .font(.ZP.display)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                
                                Text("Head Coach & Founder")
                                    .font(.ZP.title3)
                                    .foregroundStyle(Color.ZP.primary)
                            }
                            
                            // Bio
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "About Me")
                                Text("I believe in training with purpose. Whether you're an athlete or just starting out, my goal is to help you build a resilient body and mind. We don't just workout; we train.")
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                    .lineSpacing(6)
                            }
                            
                            // Philosophy
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Training Philosophy")
                                VStack(alignment: .leading, spacing: 8) {
                                    PhilosophyRow(text: "Consistency over intensity")
                                    PhilosophyRow(text: "Form is everything")
                                    PhilosophyRow(text: "Recovery is part of the work")
                                }
                            }
                            
                            // Connect
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Contact Coach")
                                }
                                .font(.ZP.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ZP.primary)
                                .foregroundStyle(Color.ZP.textBlack)
                                .cornerRadius(16)
                                .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Coach")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Components
struct PhilosophyRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.ZP.primary)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
        }
    }
}
