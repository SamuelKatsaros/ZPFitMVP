import SwiftUI
import SwiftData
import Combine

@MainActor
class TodaysWorkoutViewModel: ObservableObject {
    @Published var selectedProgram: FirestoreProgram?
    @Published var currentDay: FirestoreProgramDay?
    @Published var error: String?
    
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(firestoreService: FirestoreService, authService: AuthenticationService) {
        self.firestoreService = firestoreService
        self.authService = authService
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to current program from FirestoreService
        firestoreService.$currentProgram
            .sink { [weak self] program in
                self?.selectedProgram = program
                self?.error = nil
            }
            .store(in: &cancellables)
        
        // Subscribe to current program days
        firestoreService.$currentProgramDays
            .sink { [weak self] days in
                self?.currentDay = days.first
            }
            .store(in: &cancellables)
    }
    
    // Note: fetchData() and isLoading removed - data is now loaded once in AuthenticationService
    // and updates automatically via subscriptions above
}
