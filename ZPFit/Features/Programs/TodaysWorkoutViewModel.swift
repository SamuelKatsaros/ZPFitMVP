import SwiftUI
import SwiftData
import Combine

@MainActor
class TodaysWorkoutViewModel: ObservableObject {
    @Published var selectedProgram: FirestoreProgram?
    @Published var currentDay: FirestoreProgramDay?
    @Published var error: String?
    
    @Published var isCompleted: Bool = false
    
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(firestoreService: FirestoreService, authService: AuthenticationService) {
        self.firestoreService = firestoreService
        self.authService = authService
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to current program
        firestoreService.$currentProgram
            .sink { [weak self] program in
                self?.selectedProgram = program
                self?.error = nil
            }
            .store(in: &cancellables)
        
        // Subscribe to days AND user profile to select correct day
        Publishers.CombineLatest(firestoreService.$currentProgramDays, firestoreService.$currentUserProfile)
            .sink { [weak self] days, profile in
                self?.updateCurrentDay(days: days, profile: profile)
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentDay(days: [FirestoreProgramDay], profile: FirestoreUserProfile?) {
        guard let profile = profile else {
            currentDay = days.first
            isCompleted = false
            return
        }
        
        // Check if completed today
        if let lastCompletion = profile.lastCompletionDate, Calendar.current.isDateInToday(lastCompletion) {
            isCompleted = true
            // If completed today, show the day they just completed (currentDayNumber - 1)
            let completedDayNum = (profile.currentDayNumber ?? 1) - 1
            currentDay = days.first { $0.dayNumber == completedDayNum } ?? days.first
        } else {
            isCompleted = false
            // Show next day to complete
            let nextDayNum = profile.currentDayNumber ?? 1
            currentDay = days.first { $0.dayNumber == nextDayNum } ?? days.first
        }
    }
}
