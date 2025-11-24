import SwiftUI
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var userName: String = "Athlete"
    @Published var activeProgram: Program?
    @Published var featuredPrograms: [Program] = []
    
    private let modelContainer: ModelContainer
    private let context: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.context = modelContainer.mainContext
        fetchData()
    }
    
    func fetchData() {
        // Fetch User
        let userDescriptor = FetchDescriptor<UserProfile>()
        if let user = try? context.fetch(userDescriptor).first {
            self.userName = user.name
            self.activeProgram = user.activeProgram
        }
        
        // Fetch Programs (Mock "Featured" logic: just take the first 3)
        let programDescriptor = FetchDescriptor<Program>()
        if let programs = try? context.fetch(programDescriptor) {
            self.featuredPrograms = Array(programs.prefix(3))
        }
    }
}
