import SwiftUI

struct CoachView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero Image
                        Rectangle()
                            .fill(Color.ZP.lightCard)
                            .frame(height: 350)
                            .overlay(
                                ZStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 100))
                                        .foregroundStyle(Color.gray.opacity(0.3))
                                    
                                    LinearGradient(
                                        colors: [.clear, Color.white],
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
                                    .foregroundStyle(Color.black)
                                
                                Text("Head Coach & Founder")
                                    .font(.ZP.title3)
                                    .foregroundStyle(Color.ZP.accent)
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
                                .background(Color.ZP.accent)
                                .foregroundStyle(Color.ZP.textBlack)
                                .cornerRadius(16)
                                .shadow(color: Color.ZP.accent.opacity(0.3), radius: 10, x: 0, y: 5)
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
                .fill(Color.ZP.accent)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
        }
    }
}
