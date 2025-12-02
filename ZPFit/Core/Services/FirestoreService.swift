import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var programs: [FirestoreProgram] = []
    @Published var currentProgram: FirestoreProgram?
    @Published var currentUserProfile: FirestoreUserProfile?
    @Published var currentProgramDays: [FirestoreProgramDay] = []
    @Published var userProgress: [String: FirestoreUserProgress] = [:] // dayId -> progress
    @Published var sessions: [FirestoreSession] = []
    
    private var programsListener: ListenerRegistration?
    private var daysListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?
    private var sessionsListener: ListenerRegistration?
    
    init() {
        configureFirestore()
    }
    
    deinit {
        programsListener?.remove()
        daysListener?.remove()
        progressListener?.remove()
        sessionsListener?.remove()
    }
    
    // MARK: - Configuration
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - Programs
    
    /// Load all programs from Firestore with real-time updates
    func loadPrograms() {
        print("🔥 FirestoreService: loadPrograms() called")
        programsListener?.remove()
        
        programsListener = db.collection("programs")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading programs: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No snapshot documents")
                    return
                }
                
                print("📦 Found \(documents.count) documents in programs collection")
                
                Task { @MainActor in
                    let programs = documents.compactMap { doc -> FirestoreProgram? in
                        do {
                            let program = try doc.data(as: FirestoreProgram.self)
                            print("✅ Loaded program: \(program.title) (ID: \(program.id ?? "no-id"))")
                            return program
                        } catch {
                            print("❌ Failed to decode program from doc \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self.programs = programs
                    print("🎯 Total programs loaded: \(self.programs.count)")
                }
            }
    }
    
    /// Get a specific program by ID
    func getProgram(id: String) async throws -> FirestoreProgram? {
        let document = try await db.collection("programs").document(id).getDocument()
        return try? document.data(as: FirestoreProgram.self)
    }
    
    // MARK: - Program Days
    
    /// Load days for a specific program with real-time updates
    func loadProgramDays(programId: String) {
        daysListener?.remove()
        
        daysListener = db.collection("programs").document(programId)
            .collection("days")
            .order(by: "dayNumber")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading program days: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No days found for program")
                    return
                }
                
                Task { @MainActor in
                    self.currentProgramDays = documents.compactMap { doc in
                        do {
                            let day = try doc.data(as: FirestoreProgramDay.self)
                            print("📅 Loaded day \(day.dayNumber): '\(day.title)'")
                            print("   - difficulty: \(day.difficulty ?? "nil")")
                            print("   - duration: \(day.duration ?? 0) min")
                            return day
                        } catch {
                            print("❌ Failed to decode day from doc \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    print("🎯 Total days loaded: \(self.currentProgramDays.count)")
                }
            }
    }
    
    /// Get a specific day
    func getProgramDay(programId: String, dayId: String) async throws -> FirestoreProgramDay? {
        let document = try await db.collection("programs")
            .document(programId)
            .collection("days")
            .document(dayId)
            .getDocument()
        
        return try? document.data(as: FirestoreProgramDay.self)
    }
    
    // MARK: - Exercises
    
    /// Load exercises by their IDs
    func loadExercises(ids: [String]) async throws -> [FirestoreExercise] {
        guard !ids.isEmpty else { return [] }
        
        var exercises: [FirestoreExercise] = []
        
        // Firestore 'in' queries support max 10 items, so batch if needed
        let batches = ids.chunked(into: 10)
        
        for batch in batches {
            let snapshot = try await db.collection("exercises")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            let batchExercises = snapshot.documents.compactMap { doc in
                try? doc.data(as: FirestoreExercise.self)
            }
            
            exercises.append(contentsOf: batchExercises)
        }
        
        return exercises
    }
    
    /// Get a single exercise by ID
    func getExercise(id: String) async throws -> FirestoreExercise? {
        let document = try await db.collection("exercises").document(id).getDocument()
        return try? document.data(as: FirestoreExercise.self)
    }
    
    // MARK: - User Profile & Current Program
    
    /// Save user's selected program
    func saveCurrentProgram(userId: String, programId: String, dayNumber: Int = 1) async throws {
        print("💾 Saving program \(programId) for user \(userId)")
        
        let userRef = db.collection("users").document(userId)
        
        // Use setData with merge to ensure fields are set
        let data: [String: Any] = [
            "currentProgramId": programId,
            "currentDayNumber": dayNumber,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await userRef.setData(data, merge: true)
        
        print("✅ Successfully saved program to Firestore")
        
        // Verify the write
        let doc = try await userRef.getDocument()
        if let savedProgramId = doc.data()?["currentProgramId"] as? String {
            print("✅ Verified: currentProgramId = \(savedProgramId)")
        } else {
            print("❌ WARNING: currentProgramId not found after save!")
        }
    }
    
    /// Load user's current program
    func loadUserProfile(userId: String) async throws -> FirestoreUserProfile? {
        print("📖 Loading user profile for: \(userId)")
        let document = try await db.collection("users").document(userId).getDocument()
        
        if let data = document.data() {
            print("📄 User document data: \(data)")
            
            // Try to decode with error handling
            do {
                let profile = try document.data(as: FirestoreUserProfile.self)
                print("✅ Successfully decoded user profile")
                print("   - currentProgramId: \(profile.currentProgramId ?? "nil")")
                print("   - currentDayNumber: \(profile.currentDayNumber ?? 0)")
                return profile
            } catch {
                print("❌ Failed to decode FirestoreUserProfile: \(error)")
                // Return a manually constructed profile as fallback
                return FirestoreUserProfile(
                    id: userId,
                    email: data["email"] as? String,
                    name: data["name"] as? String,
                    currentProgramId: data["currentProgramId"] as? String,
                    currentDayNumber: data["currentDayNumber"] as? Int,
                    joinedDate: nil,
                    experienceLevel: data["experienceLevel"] as? String,
                    goal: data["goal"] as? String,
                    updatedAt: nil
                )
            }
        } else {
            return nil
        }
    }
    
    /// Load all user data (profile, program, days, progress) in one call
    /// This should be called once at login/app launch to cache all necessary data
    func loadUserData(userId: String) async {
        print("🔄 Loading all user data for: \(userId)")
        
        do {
            // Load user profile
            if let profile = try await loadUserProfile(userId: userId) {
                await MainActor.run {
                    self.currentUserProfile = profile
                }
                
                // Load user's current program if they have one
                if let programId = profile.currentProgramId {
                    print("📱 User has program: \(programId)")
                    
                    // Load the program
                    if let program = try? await getProgram(id: programId) {
                        await MainActor.run {
                            self.currentProgram = program
                            print("✅ Cached program: \(program.title)")
                        }
                        
                        // Load program days (using real-time listener)
                        loadProgramDays(programId: programId)
                        
                        // Load user progress for this program (using real-time listener)
                        loadUserProgress(userId: userId, programId: programId)
                    }
                } else {
                    print("⚠️ User has no program selected")
                    await MainActor.run {
                        self.currentProgram = nil
                        self.currentProgramDays = []
                    }
                }
            }
        } catch {
            print("❌ Error loading user data: \(error.localizedDescription)")
        }
    }
    
    /// Clear all cached user data (call on sign out)
    func clearUserData() {
        currentUserProfile = nil
        currentProgram = nil
        currentProgramDays = []
        userProgress = [:]
        removeAllListeners()
    }

    
    /// Create or update user profile
    func createUserProfile(userId: String, email: String, name: String?) async throws {
        let userRef = db.collection("users").document(userId)
        
        let profile: [String: Any] = [
            "email": email,
            "name": name ?? "",
            "joinedDate": FieldValue.serverTimestamp(),
            "currentProgramId": NSNull(),
            "currentDayNumber": 0
        ]
        
        try await userRef.setData(profile, merge: false)
    }
    
    /// Update user profile fields (e.g., to clear current program)
    func updateUserProfile(
        userId: String,
        currentProgramId: String?,
        currentDayNumber: Int?
    ) async throws {
        let userRef = db.collection("users").document(userId)
        
        var updates: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let programId = currentProgramId {
            updates["currentProgramId"] = programId
        } else {
            updates["currentProgramId"] = FieldValue.delete()
        }
        
        if let dayNumber = currentDayNumber {
            updates["currentDayNumber"] = dayNumber
        } else {
            updates["currentDayNumber"] = FieldValue.delete()
        }
        
        try await userRef.updateData(updates)
        print("✅ Updated user profile")
    }
    
    // MARK: - Progress Tracking
    
    /// Save workout progress
    func saveProgress(
        userId: String,
        programId: String,
        dayId: String,
        status: ProgressStatus,
        exercisesCompleted: [String] = []
    ) async throws {
        let progressRef = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(dayId)
        
        let progress = FirestoreUserProgress(
            id: dayId,
            dayId: dayId,
            programId: programId,
            status: status,
            completedAt: Date(),
            exercisesCompleted: exercisesCompleted
        )
        
        try progressRef.setData(from: progress, merge: true)
    }
    
    /// Load user's progress for a program with real-time updates
    func loadUserProgress(userId: String, programId: String) {
        progressListener?.remove()
        
        progressListener = db.collection("users")
            .document(userId)
            .collection("progress")
            .whereField("programId", isEqualTo: programId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading progress: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                Task { @MainActor in
                    var progressMap: [String: FirestoreUserProgress] = [:]
                    for doc in documents {
                        if let progress = try? doc.data(as: FirestoreUserProgress.self) {
                            progressMap[progress.dayId] = progress
                        }
                    }
                    self.userProgress = progressMap
                }
            }
    }
    
    /// Get progress for a specific day
    func getProgress(userId: String, dayId: String) async throws -> FirestoreUserProgress? {
        let document = try await db.collection("users")
            .document(userId)
            .collection("progress")
            .document(dayId)
            .getDocument()
        
        return try? document.data(as: FirestoreUserProgress.self)
    }
    
    // MARK: - Sessions
    
    /// Load sessions (Quick Workouts/Reels) with real-time updates
    func loadSessions() {
        print("🔥 FirestoreService: loadSessions() called")
        sessionsListener?.remove()
        
        sessionsListener = db.collection("sessions")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading sessions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No snapshot documents for sessions")
                    return
                }
                
                print("📦 Found \(documents.count) documents in sessions collection")
                
                Task { @MainActor in
                    let sessions = documents.compactMap { doc -> FirestoreSession? in
                        do {
                            let session = try doc.data(as: FirestoreSession.self)
                            print("✅ Loaded session: \(session.title) (ID: \(session.id ?? "no-id"))")
                            return session
                        } catch {
                            print("❌ Failed to decode session from doc \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self.sessions = sessions
                    print("🎯 Total sessions loaded: \(self.sessions.count)")
                }
            }
    }
    
    // MARK: - Helper Methods
    
    /// Remove all listeners
    func removeAllListeners() {
        programsListener?.remove()
        daysListener?.remove()
        progressListener?.remove()
        sessionsListener?.remove()
    }
}

// MARK: - Array Extension for Batching

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
