import SwiftUI

struct ActiveProgramView: View {
    @StateObject private var viewModel: TodaysWorkoutViewModel
    @Environment(\.diContainer) private var diContainer
    @State private var showWorkout = false
    @State private var showChangeProgramAlert = false
    
    init() {
        _viewModel = StateObject(wrappedValue: TodaysWorkoutViewModel(
            firestoreService: DIContainer.shared.firestoreService,
            authService: DIContainer.shared.authenticationService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                if let program = viewModel.selectedProgram, let day = viewModel.currentDay {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Program Header
                            ZStack(alignment: .bottomLeading) {
                                AsyncImage(url: URL(string: program.coverImage)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    default:
                                        Color.ZP.card
                                    }
                                }
                                .frame(height: 300)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(program.title)
                                        .font(.ZP.display)
                                        .foregroundStyle(.white)
                                    
                                    Text("Week \(Int(ceil(Double(day.dayNumber) / 7.0))) • Day \(day.dayNumber)")
                                        .font(.ZP.title3)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .padding(20)
                            }
                            
                            // Today's Workout Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Today's Session")
                                    .font(.ZP.title2)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                Button(action: { showWorkout = true }) {
                                    HStack(spacing: 16) {
                                        // Thumbnail
                                        AsyncImage(url: URL(string: day.thumbnailUrl ?? program.coverImage)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Color.ZP.cardHover
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(12)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.title)
                                                .font(.ZP.headline)
                                                .foregroundStyle(Color.ZP.textPrimary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text("\(day.durationMinutes) min • \(day.exercises.count) Exercises")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(Color.blue)
                                    }
                                    .padding(16)
                                    .background(Color.ZP.card)
                                    .cornerRadius(20)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Change Program Button
                            Button(action: { showChangeProgramAlert = true }) {
                                Text("Change Program")
                                    .font(.ZP.subheadline)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .ignoresSafeArea(edges: .top)
                } else {
                    ProgressView()
                }
            }
            .fullScreenCover(isPresented: $showWorkout) {
                TodaysWorkoutView()
            }
            .alert("Change Program?", isPresented: $showChangeProgramAlert) {
                Button("Cancel", role: .cancel) { }
                Button("End Current Program", role: .destructive) {
                    Task {
                        if let userId = diContainer.authenticationService.currentUserId {
                            try? await diContainer.firestoreService.updateUserProfile(
                                userId: userId,
                                currentProgramId: nil,
                                currentDayNumber: nil
                            )
                            NotificationCenter.default.post(name: NSNotification.Name("ProgramSelected"), object: nil)
                        }
                    }
                }
            } message: {
                Text("This will end your current progress and return you to the program list.")
            }
        }
    }
}
