import SwiftUI
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var selectedProgram: FirestoreProgram?
    @Published var currentDay: FirestoreProgramDay?
    @Published var todayExercises: [FirestoreExercise] = []
    @Published var userProgress: [String: FirestoreUserProgress] = [:]
    
    private let modelContainer: ModelContainer
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContainer: ModelContainer, firestoreService: FirestoreService, authService: AuthenticationService) {
        self.modelContainer = modelContainer
        self.firestoreService = firestoreService
        self.authService = authService
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to current program from FirestoreService
        firestoreService.$currentProgram
            .assign(to: &$selectedProgram)
        
        // Subscribe to current program days
        firestoreService.$currentProgramDays
            .sink { [weak self] days in
                self?.currentDay = days.first
            }
            .store(in: &cancellables)
        
        // Subscribe to user progress
        firestoreService.$userProgress
            .assign(to: &$userProgress)
    }
    
    // Note: fetchData() removed - data is now loaded once in AuthenticationService
    // and updates automatically via subscriptions above

    
    func loadTodayExercises() async {
        guard let day = currentDay else { return }
        
        // Convert embedded exercises to FirestoreExercise objects
        let exercises = day.exercises.enumerated().map { index, embedded -> FirestoreExercise in
            FirestoreExercise(
                id: "\(day.id ?? "day")_\(index)",
                name: embedded.name,
                instructions: nil,
                videoUrl: embedded.videoUrl,
                thumbnailUrl: embedded.thumbnailUrl,
                muscleGroup: nil,
                durationSeconds: nil,
                reps: embedded.reps,
                sets: embedded.sets
            )
        }
        
        await MainActor.run {
            todayExercises = exercises
        }
    }
}
