import SwiftUI
import Combine

/// ViewModel for run history list
@MainActor
class RunHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var runs: [FirestoreRun] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(firestoreService: FirestoreService, authService: AuthenticationService) {
        self.firestoreService = firestoreService
        self.authService = authService
        
        setupSubscriptions()
        loadRuns()
    }
    
    // MARK: - Public Methods
    
    func loadRuns() {
        guard let userId = authService.currentUserId else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        firestoreService.loadRuns(userId: userId)
    }
    
    func deleteRun(_ run: FirestoreRun) async {
        guard let userId = authService.currentUserId,
              let runId = run.id else { return }
        
        do {
            try await firestoreService.deleteRun(userId: userId, runId: runId)
        } catch {
            errorMessage = "Failed to delete run"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        firestoreService.$runs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] runs in
                self?.runs = runs
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
}
