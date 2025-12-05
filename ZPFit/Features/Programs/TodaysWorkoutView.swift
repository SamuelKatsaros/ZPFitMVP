import SwiftUI
import SwiftData

struct TodaysWorkoutView: View {
    @StateObject private var viewModel: TodaysWorkoutViewModel
    @Environment(\.diContainer) private var diContainer
    @Environment(\.dismiss) private var dismiss
    @State private var showChangeProgramAlert = false
    @State private var selectedExercise: FirestoreProgramDay.EmbeddedExercise?
    @State private var isCompleting = false
    
    // Parallax scroll tracking
    @State private var scrollOffset: CGFloat = 0
    
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
                
                if let error = viewModel.error {
                    ErrorView(error: error)
                } else if let program = viewModel.selectedProgram,
                          let day = viewModel.currentDay {
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 0) {
                            // Parallax Header
                            GeometryReader { geometry in
                                let minY = geometry.frame(in: .global).minY
                                let height = geometry.size.height + (minY > 0 ? minY : 0)
                                
                                ZStack(alignment: .bottom) {
                                    // Background Image
                                    if let thumbnailUrl = day.thumbnailUrl, !thumbnailUrl.isEmpty {
                                        AsyncImage(url: URL(string: thumbnailUrl)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: geometry.size.width, height: height)
                                                    .clipped()
                                            default:
                                                // Fallback to program cover if day thumbnail missing
                                                AsyncImage(url: URL(string: program.coverImage)) { pPhase in
                                                    if let pImage = pPhase.image {
                                                        pImage
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: geometry.size.width, height: height)
                                                            .clipped()
                                                    } else {
                                                        Color.ZP.card
                                                            .frame(width: geometry.size.width, height: height)
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        Color.ZP.card
                                            .frame(width: geometry.size.width, height: height)
                                    }
                                    
                                    // Gradient Overlay
                                    LinearGradient(
                                        colors: [
                                            .black.opacity(0.1),
                                            .black.opacity(0.4),
                                            Color.ZP.background
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: height)
                                    
                                    // Header Content
                                    VStack(alignment: .leading, spacing: 12) {
                                        Spacer()
                                        
                                        // Day Badge
                                        Text("DAY \(day.dayNumber)")
                                            .font(.system(size: 14, weight: .bold))
                                            .tracking(2)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                        
                                        // Title
                                        Text(day.title)
                                            .font(.system(size: 42, weight: .black))
                                            .foregroundStyle(.white)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                        
                                        // Description
                                        if !day.description.isEmpty {
                                            Text(day.description)
                                                .font(.ZP.body)
                                                .foregroundStyle(.white.opacity(0.9))
                                                .lineLimit(3)
                                                .shadow(color: .black.opacity(0.5), radius: 2)
                                        }
                                        
                                        // Stats Row
                                        HStack(spacing: 24) {
                                            StatItem(icon: "clock.fill", value: "\(day.durationMinutes) min", label: "Duration")
                                            StatItem(icon: "dumbbell.fill", value: "\(day.exercises.count)", label: "Exercises")
                                        }
                                        .padding(.top, 16)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 40)
                                }
                                .offset(y: minY > 0 ? -minY : 0)
                            }
                            .frame(height: 450)
                            
                                // Exercise List
                                VStack(alignment: .leading, spacing: 24) {
                                    // Spacing for top overlap
                                    Color.clear.frame(height: 20)
                                    
                                    if !day.exercises.isEmpty {
                                    LazyVStack(spacing: 16) {
                                        ForEach(day.exercises.indices, id: \.self) { index in
                                            Button(action: {
                                                if let videoUrl = day.exercises[index].videoUrl,
                                                   !videoUrl.isEmpty {
                                                    selectedExercise = day.exercises[index]
                                                }
                                            }) {
                                                PremiumExerciseCard(exercise: day.exercises[index], index: index + 1)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                } else {
                                    Text("No exercises for today.")
                                        .font(.ZP.body)
                                        .foregroundStyle(Color.ZP.textSecondary)
                                        .padding(.horizontal, 24)
                                }
                                
                                // Complete Workout Button (Inline)
                                if viewModel.isCompleted {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color.green)
                                        Text("Workout Completed")
                                            .font(.ZP.headline)
                                            .foregroundStyle(Color.ZP.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.ZP.card)
                                    .cornerRadius(20)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                                } else {
                                    Button(action: {
                                        completeWorkout(program: program, day: day)
                                    }) {
                                        HStack {
                                            if isCompleting {
                                                ProgressView()
                                                    .tint(.white)
                                            } else {
                                                Text("Complete Workout")
                                                    .font(.system(size: 18, weight: .bold))
                                            }
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 8)
                                    }
                                    .disabled(isCompleting)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                                }
                            }
                            .background(Color.ZP.background)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .offset(y: -30) // Overlap effect
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    
                    // Back Button Overlay
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60) // Adjust for safe area
                        
                        Spacer()
                    }
                    
                } else {
                    NoWorkoutView()
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $selectedExercise) { exercise in
            if let videoUrl = exercise.videoUrl, let url = URL(string: videoUrl) {
                FullScreenVideoPlayer(videoURL: url, exercise: exercise)
            }
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
            if let program = viewModel.selectedProgram {
                Text("This will end your current progress on \(program.title) and return you to the program list.")
            } else {
                Text("This will end your current program.")
            }
        }
    }
    
    private func completeWorkout(program: FirestoreProgram, day: FirestoreProgramDay) {
        guard let userId = diContainer.authenticationService.currentUserId,
              let programId = program.id,
              let dayId = day.id else { return }
        
        isCompleting = true
        
        Task {
            do {
                try await diContainer.firestoreService.markDayCompleted(
                    userId: userId,
                    programId: programId,
                    dayId: dayId,
                    dayNumber: day.dayNumber,
                    durationMinutes: day.durationMinutes
                )
                
                await MainActor.run {
                    isCompleting = false
                    withAnimation {
                        viewModel.isCompleted = true
                    }
                }
            } catch {
                print("Error completing workout: \(error)")
                await MainActor.run {
                    isCompleting = false
                }
            }
        }
    }
}

// MARK: - Subviews

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
        }
    }
}

struct PremiumExerciseCard: View {
    let exercise: FirestoreProgramDay.EmbeddedExercise
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Index
            Text("\(index)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.ZP.textSecondary.opacity(0.3))
                .frame(width: 30)
            
            // Thumbnail
            AsyncImage(url: URL(string: exercise.thumbnailUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    Color.ZP.cardHover
                        .overlay(ProgressView())
                default:
                    Color.ZP.cardHover
                        .overlay(
                            Image(systemName: "figure.run")
                                .foregroundStyle(Color.ZP.textSecondary)
                        )
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let sets = exercise.sets {
                        Label("\(sets) Sets", systemImage: "arrow.triangle.2.circlepath")
                    }
                    if let reps = exercise.reps {
                        Label("\(reps) Reps", systemImage: "repeat")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.ZP.textSecondary)
            }
            
            Spacer()
            
            // Play Button
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.blue)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(16)
        .background(Color.ZP.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct NoWorkoutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ZP.textSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Active Program")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("Select a program from the Home tab to start your journey.")
                    .font(.ZP.body)
                    .foregroundStyle(Color.ZP.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.red)
            
            Text("Something went wrong")
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Text(error)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

extension FirestoreProgramDay.EmbeddedExercise: Identifiable {
    public var id: String { name + (videoUrl ?? "") }
}
