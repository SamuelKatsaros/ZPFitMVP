import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: Program
    @Environment(\.diContainer) private var diContainer
    @Environment(\.dismiss) private var dismiss
    
    // We need to access UserProfile to enroll
    @Query private var userProfiles: [UserProfile]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                Rectangle()
                    .fill(Color.ZP.lightCard)
                    .frame(height: 300)
                    .overlay(
                        ZStack {
                            Image(systemName: "figure.cross.training")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.gray.opacity(0.3))
                            
                            LinearGradient(
                                colors: [.clear, Color.white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title & Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(program.title)
                            .font(.ZP.display)
                            .foregroundStyle(Color.black)
                        
                        Text(program.subtitle)
                            .font(.ZP.title3)
                            .foregroundStyle(Color.gray)
                        
                        HStack(spacing: 16) {
                            Label("\(program.durationWeeks) Weeks", systemImage: "calendar")
                            Label(program.difficulty, systemImage: "chart.bar.fill")
                        }
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.accent)
                    }
                    
                    // Enroll Button
                    Button(action: enrollInProgram) {
                        Text("Start Program")
                            .font(.ZP.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ZP.accent)
                            .foregroundStyle(Color.ZP.textBlack)
                            .cornerRadius(16)
                            .shadow(color: Color.ZP.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Workouts List (Grouped by week - simplified for now)
                    Text("Schedule")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.black)
                    
                    ForEach(program.workouts) { workout in
                        Button(action: { selectedWorkout = workout }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(workout.title)
                                        .font(.ZP.headline)
                                        .foregroundStyle(Color.black)
                                    Text("\(workout.durationMinutes) min • \(workout.type)")
                                        .font(.ZP.subheadline)
                                        .foregroundStyle(Color.gray)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.ZP.accent)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedWorkout) { workout in
            WorkoutPlayerView(workout: workout)
        }
    }
    
    @State private var selectedWorkout: Workout?
    
    private func enrollInProgram() {
        guard let user = userProfiles.first else { return }
        user.activeProgram = program
        // In a real app, we'd save context here via a service or direct context access
        // For now, assuming autosave or service handling
        // We can use the service if we want to be clean
        // diContainer.userProfileService.setActiveProgram(program)
        // But direct assignment works with SwiftData if context is saved.
        try? diContainer.persistenceService.container.mainContext.save()
        dismiss()
    }
}
