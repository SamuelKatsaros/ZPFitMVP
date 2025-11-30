import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: Program
    @Environment(\.diContainer) private var diContainer
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedPlan") private var selectedPlan: String?
    
    // We need to access UserProfile to enroll
    @Query private var userProfiles: [UserProfile]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: program.coverImage)) { phase in
                        switch phase {
                        case .empty:
                            Color.ZP.card.overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Color.ZP.card
                                .overlay(
                                    Image(systemName: "figure.cross.training")
                                        .font(.system(size: 80))
                                        .foregroundStyle(Color.ZP.textSecondary.opacity(0.3))
                                )
                        @unknown default:
                            Color.ZP.card
                        }
                    }
                    .frame(height: 350)
                    .clipped()
                    
                    LinearGradient(
                        colors: [.clear, Color.ZP.background.opacity(0.8), Color.ZP.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title & Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(program.title)
                            .font(.ZP.display)
                            .foregroundStyle(Color.ZP.textPrimary)
                        
                        Text(program.subtitle)
                            .font(.ZP.title3)
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        HStack(spacing: 12) {
                            Badge(text: "\(program.durationWeeks) WEEKS", icon: "calendar", color: .blue)
                            Badge(text: program.difficulty.uppercased(), icon: "chart.bar.fill", color: .orange)
                        }
                    }
                    
                    // Enroll Button
                    Button(action: enrollInProgram) {
                        Text("Start Program")
                            .font(.ZP.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ZP.primary)
                            .foregroundStyle(Color.ZP.textBlack)
                            .cornerRadius(16)
                            .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Description
                    Text("This program is designed to push your limits. Follow the schedule strictly for best results. Ensure you have access to a gym with basic equipment.")
                        .font(.ZP.body)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .lineLimit(4)
                    
                    // Workouts List
                    Text("Schedule")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        ForEach(program.workouts) { workout in
                            Button(action: { selectedWorkout = workout }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.ZP.cardHover)
                                            .frame(width: 48, height: 48)
                                        
                                        if workout.type == "Rest" {
                                            Image(systemName: "moon.fill")
                                                .foregroundStyle(Color.purple)
                                        } else {
                                            Text(String(workout.title.prefix(1)))
                                                .font(.headline)
                                                .foregroundStyle(Color.ZP.primary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(workout.title)
                                            .font(.ZP.headline)
                                            .foregroundStyle(Color.ZP.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack {
                                            Text(workout.type)
                                                .font(.ZP.caption)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                            
                                            if workout.durationMinutes > 0 {
                                                Text("•")
                                                    .foregroundStyle(Color.ZP.textTertiary)
                                                Text("\(workout.durationMinutes) min")
                                                    .font(.ZP.caption)
                                                    .foregroundStyle(Color.ZP.textSecondary)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ZP.textTertiary)
                                }
                                .padding(16)
                                .background(Color.ZP.card)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(20)
                .offset(y: -40) // Overlap with image
            }
        }
        .background(Color.ZP.background)
        .ignoresSafeArea(edges: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            WorkoutPlayerView(workout: workout)
        }
    }
    
    @State private var selectedWorkout: Workout?
    
    private func enrollInProgram() {
        guard let user = userProfiles.first else { return }
        user.activeProgram = program
        selectedPlan = program.id // Update AppStorage
        
        try? diContainer.persistenceService.container.mainContext.save()
        dismiss()
    }
}

struct Badge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .cornerRadius(8)
        .foregroundStyle(color)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
