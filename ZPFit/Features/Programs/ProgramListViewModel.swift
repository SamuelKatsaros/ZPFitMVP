import Foundation
import SwiftUI
import Combine

@MainActor
class ProgramListViewModel: ObservableObject {
    @Published var programs: [FirestoreProgram] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(firestoreService: FirestoreService, authService: AuthenticationService) {
        self.firestoreService = firestoreService
        self.authService = authService
        
        // Subscribe to programs from Firestore
        firestoreService.$programs
            .assign(to: &$programs)
    }
    
    func loadPrograms() {
        isLoading = true
        errorMessage = nil
        firestoreService.loadPrograms()
        
        // Simulate loading delay for UI feedback
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isLoading = false
        }
    }
    
    func selectProgram(_ program: FirestoreProgram) async {
        guard let userId = authService.currentUserId,
              let programId = program.id else {
            errorMessage = "Unable to select program"
            return
        }
        
        // Prevent duplicate selections
        guard !isLoading else {
            print("⚠️ Already selecting a program, ignoring")
            return
        }
        
        isLoading = true
        
        do {
            // Save to Firestore only - no more AppStorage
            try await firestoreService.saveCurrentProgram(userId: userId, programId: programId, dayNumber: 1)
            
            print("✅ Program selected: \(program.title)")
            
            // Reload user data to update cache and notify all subscribers
            await firestoreService.loadUserData(userId: userId)
            
        } catch {
            errorMessage = "Failed to save program selection: \(error.localizedDescription)"
            print("❌ Error selecting program: \(error)")
        }
        
        isLoading = false
    }
}
