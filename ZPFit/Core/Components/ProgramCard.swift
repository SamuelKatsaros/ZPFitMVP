import SwiftUI

struct ProgramCard: View {
    let program: Program
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image Placeholder
            Rectangle()
                .fill(Color.ZP.card)
                .overlay(
                    Image(systemName: "dumbbell.fill") // Placeholder
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .foregroundStyle(Color.ZP.cardHover)
                        .offset(x: 80, y: -20)
                )
            
            // Gradient Overlay
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(program.title)
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text(program.subtitle)
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(program.durationWeeks) Weeks", systemImage: "calendar")
                    Spacer()
                    Label(program.difficulty, systemImage: "chart.bar.fill")
                }
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.accent)
            }
            .padding()
        }
        .frame(height: 200)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.ZP.cardHover, lineWidth: 1)
        )
    }
}
