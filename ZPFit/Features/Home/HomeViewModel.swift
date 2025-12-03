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
    @Published var sessions: [FirestoreSession] = []
    
    // Completion tracking
    @Published var completedToday: Bool = false
    @Published var nextAvailableDay: Int = 1
    
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
                self?.updateCurrentDay(days: days)
            }
            .store(in: &cancellables)
        
        // Subscribe to user progress
        firestoreService.$userProgress
            .assign(to: &$userProgress)
        
        // Subscribe to sessions
        firestoreService.$sessions
            .assign(to: &$sessions)
        
        // Subscribe to user profile for completion tracking and day updates
        firestoreService.$currentUserProfile
            .sink { [weak self] profile in
                self?.checkCompletionStatus(profile: profile)
                // Also update current day selection as profile changes (e.g. day number incremented)
                if let days = self?.firestoreService.currentProgramDays {
                    self?.updateCurrentDay(days: days)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentDay(days: [FirestoreProgramDay]) {
        // Get the user's next available day
        if let profile = firestoreService.currentUserProfile {
            let userCurrentDay = profile.currentDayNumber ?? 1
            
            // Check if completed today
            let completedToday = checkIfCompletedToday(profile: profile)
            
            if completedToday {
                // Show the day they just completed
                currentDay = days.first { $0.dayNumber == userCurrentDay - 1 }
                nextAvailableDay = userCurrentDay
            } else {
                // Show next day to complete
                currentDay = days.first { $0.dayNumber == userCurrentDay }
                nextAvailableDay = userCurrentDay
            }
        } else {
            currentDay = days.first
            nextAvailableDay = 1
        }
    }
    
    private func checkCompletionStatus(profile: FirestoreUserProfile?) {
        guard let profile = profile else {
            completedToday = false
            return
        }
        
        completedToday = checkIfCompletedToday(profile: profile)
    }
    
    private func checkIfCompletedToday(profile: FirestoreUserProfile) -> Bool {
        guard let lastCompletion = profile.lastCompletionDate else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(lastCompletion)
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
