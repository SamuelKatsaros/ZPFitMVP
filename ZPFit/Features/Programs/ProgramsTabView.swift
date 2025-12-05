import SwiftUI

/// Wrapper view for Programs tab - shows workout if program selected, otherwise shows program list
struct ProgramsTabView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var hasProgram = false
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.ZP.background.ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            } else if hasProgram {
                ActiveProgramView()
            } else {
                ProgramListView()
            }
        }
        .onAppear {
            checkForProgram()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProgramSelected"))) { _ in
            checkForProgram()
        }
    }
    
    private func checkForProgram() {
        Task {
            isLoading = true
            
            if let userId = diContainer.authenticationService.currentUserId {
                do {
                    let profile = try await diContainer.firestoreService.loadUserProfile(userId: userId)
                    await MainActor.run {
                        hasProgram = profile?.currentProgramId != nil
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        hasProgram = false
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    hasProgram = false
                    isLoading = false
                }
            }
        }
    }
}
