import SwiftUI
import SwiftData

struct TodaysWorkoutView: View {
    @StateObject private var viewModel: TodaysWorkoutViewModel
    @Environment(\.diContainer) private var diContainer
    @State private var showChangeProgramAlert = false
    
    @State private var selectedVideoUrl: URL?
    
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
                    WorkoutContent(
                        program: program,
                        day: day,
                        isCompleted: viewModel.isCompleted,
                        showChangeProgramAlert: $showChangeProgramAlert,
                        onExerciseTap: { urlString in
                            if let urlString = urlString, let url = URL(string: urlString) {
                                selectedVideoUrl = url
                            }
                        }
                    )
                } else {
                    NoWorkoutView()
                }
            }
        }
        .fullScreenCover(item: $selectedVideoUrl) { url in
            FullScreenVideoPlayer(videoURL: url)
        }
    }
    
    struct WorkoutContent: View {
        let program: FirestoreProgram
        let day: FirestoreProgramDay
        let isCompleted: Bool
        @Binding var showChangeProgramAlert: Bool
        let onExerciseTap: (String?) -> Void
        @Environment(\.diContainer) private var diContainer
        
        @State private var isCompleting = false
        @State private var showCompletionSuccess = false
        
        var body: some View {
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Workout")
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textSecondary)
                        Text(program.title)
                            .font(.ZP.title3)
                            .foregroundStyle(Color.ZP.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showChangeProgramAlert = true }) {
                        Text("Change Program")
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ZP.card)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // Workout Details
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Day header
                        VStack(alignment: .leading, spacing: 8) {
                            // Thumbnail
                            if let thumbnailUrl = day.thumbnailUrl, !thumbnailUrl.isEmpty {
                                AsyncImage(url: URL(string: thumbnailUrl)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 220)
                                            .clipped()
                                            .cornerRadius(20)
                                    case .failure:
                                        Color.ZP.card
                                            .frame(height: 220)
                                            .cornerRadius(20)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(Color.ZP.textSecondary)
                                            )
                                    case .empty:
                                        Color.ZP.card
                                            .frame(height: 220)
                                            .cornerRadius(20)
                                            .overlay(ProgressView())
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                            
                            Text("Day \(day.dayNumber)")
                                .font(.ZP.caption)
                                .foregroundStyle(Color.ZP.textSecondary)
                            
                            Text(day.title)
                                .font(.ZP.title1)
                                .foregroundStyle(Color.ZP.textPrimary)
                            
                            if !day.description.isEmpty {
                                Text(day.description)
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Exercises
                        if !day.exercises.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Exercises")
                                    .font(.ZP.title3)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                ForEach(day.exercises.indices, id: \.self) { index in
                                    Button(action: {
                                        onExerciseTap(day.exercises[index].videoUrl)
                                    }) {
                                        ExerciseCard(exercise: day.exercises[index])
                                    }
                                    .padding([.leading, .trailing], 20)
                                }
                            }
                        }
                        
                        // Complete Workout button
                        if showCompletionSuccess {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.green)
                                
                                Text("Workout Completed!")
                                    .font(.ZP.title2)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                
                                Text("Great job! Come back tomorrow for Day \(day.dayNumber + 1).")
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ZP.card)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        } else {
                            Button(action: {
                                completeWorkout()
                            }) {
                                ZStack {
                                    if isCompleting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Complete Workout")
                                            .font(.ZP.headline)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isCompleting)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
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
                Text("This will end your current progress on \(program.title) and return you to the program list.")
            }
            .onAppear {
                if isCompleted {
                    showCompletionSuccess = true
                }
            }
            .onChange(of: isCompleted) { completed in
                if completed {
                    showCompletionSuccess = true
                }
            }
        }
        
        private func completeWorkout() {
            guard let userId = diContainer.authenticationService.currentUserId,
                  let programId = program.id,
                  let dayId = day.id else {
                return
            }
            
            isCompleting = true
            
            Task {
                do {
                    try await diContainer.firestoreService.markDayCompleted(
                        userId: userId,
                        programId: programId,
                        dayId: dayId,
                        dayNumber: day.dayNumber,
                        durationMinutes: day.duration
                    )
                    
                    await MainActor.run {
                        isCompleting = false
                        withAnimation {
                            showCompletionSuccess = true
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
    
    struct ExerciseCard: View {
        let exercise: FirestoreProgramDay.EmbeddedExercise
        
        var body: some View {
            HStack(spacing: 16) {
                // Thumbnail
                AsyncImage(url: URL(string: exercise.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        Color.ZP.cardHover
                            .overlay(
                                ProgressView()
                            )
                    case .failure(let error):
                        let _ = print("❌ Workout Image load failed: \(error)")
                        Color.ZP.cardHover
                            .overlay(
                                VStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            )
                    @unknown default:
                        Color.ZP.cardHover
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                
                // Exercise info
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        if let sets = exercise.sets {
                            Text("\(sets) sets")
                                .font(.ZP.subheadline)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                        
                        if let reps = exercise.reps {
                            Text("\(reps) reps")
                                .font(.ZP.subheadline)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.blue)
            }
            .padding(16)
            .background(Color.ZP.card)
            .cornerRadius(16)
        }
    }
    
    struct NoWorkoutView: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ZP.textSecondary)
                
                Text("No Workout Today")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("Select a program to get started")
                    .font(.ZP.body)
                    .foregroundStyle(Color.ZP.textSecondary)
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
                
                Text("Error")
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
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

