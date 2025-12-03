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
                    firstName: nil,
                    lastName: nil,
                    dateOfBirth: nil,
                    heightFeet: nil,
                    heightInches: nil,
                    weightPounds: nil,
                    experienceLevel: data["experienceLevel"] as? String,
                    goals: nil,
                    name: data["name"] as? String,
                    goal: data["goal"] as? String,
                    currentProgramId: data["currentProgramId"] as? String,
                    currentDayNumber: data["currentDayNumber"] as? Int,
                    lastCompletionDate: nil,
                    joinedDate: nil,
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

    
    /// Create or update user profile with complete information
    func createUserProfile(
        userId: String,
        email: String,
        firstName: String?,
        lastName: String?,
        dateOfBirth: Date?,
        heightFeet: Int?,
        heightInches: Int?,
        weightPounds: Int?,
        experienceLevel: String?,
        goals: [String]?
    ) async throws {
        let userRef = db.collection("users").document(userId)
        
        var profile: [String: Any] = [
            "email": email,
            "joinedDate": FieldValue.serverTimestamp(),
            "currentDayNumber": 0,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Add optional fields if provided
        if let firstName = firstName {
            profile["firstName"] = firstName
        }
        if let lastName = lastName {
            profile["lastName"] = lastName
        }
        if let dob = dateOfBirth {
            profile["dateOfBirth"] = Timestamp(date: dob)
        }
        if let feet = heightFeet {
            profile["heightFeet"] = feet
        }
        if let inches = heightInches {
            profile["heightInches"] = inches
        }
        if let weight = weightPounds {
            profile["weightPounds"] = weight
        }
        if let experience = experienceLevel {
            profile["experienceLevel"] = experience
        }
        if let goals = goals, !goals.isEmpty {
            profile["goals"] = goals
        }
        
        // Set currentProgramId to null initially
        profile["currentProgramId"] = NSNull()
        
        try await userRef.setData(profile, merge: false)
        print("✅ Created user profile with complete data")
    }
    
    
    /// Update user profile fields - comprehensive version
    func updateUserProfile(
        userId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: Date? = nil,
        heightFeet: Int? = nil,
        heightInches: Int? = nil,
        weightPounds: Int? = nil,
        experienceLevel: String? = nil,
        goals: [String]? = nil,
        currentProgramId: String? = nil,
        currentDayNumber: Int? = nil,
        lastCompletionDate: Date? = nil
    ) async throws {
        let userRef = db.collection("users").document(userId)
        
        var updates: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Update optional fields if provided
        if let firstName = firstName {
            updates["firstName"] = firstName
        }
        if let lastName = lastName {
            updates["lastName"] = lastName
        }
        if let dob = dateOfBirth {
            updates["dateOfBirth"] = Timestamp(date: dob)
        }
        if let feet = heightFeet {
            updates["heightFeet"] = feet
        }
        if let inches = heightInches {
            updates["heightInches"] = inches
        }
        if let weight = weightPounds {
            updates["weightPounds"] = weight
        }
        if let experience = experienceLevel {
            updates["experienceLevel"] = experience
        }
        if let goals = goals {
            updates["goals"] = goals
        }
        if let programId = currentProgramId {
            updates["currentProgramId"] = programId
        }
        if let dayNumber = currentDayNumber {
            updates["currentDayNumber"] = dayNumber
        }
        if let completionDate = lastCompletionDate {
            updates["lastCompletionDate"] = Timestamp(date: completionDate)
        }
        
        try await userRef.updateData(updates)
        print("✅ Updated user profile")
    }
    
    // MARK: - Day Completion Tracking
    
    /// Mark a day as completed
    func markDayCompleted(
        userId: String,
        programId: String,
        dayId: String,
        dayNumber: Int,
        durationMinutes: Int? = nil
    ) async throws {
        let completionRef = db.collection("users")
            .document(userId)
            .collection("completions")
            .document() // Auto-generate ID
        
        let completion = FirestoreDayCompletion(
            id: completionRef.documentID,
            programId: programId,
            dayId: dayId,
            dayNumber: dayNumber,
            completedAt: Date(),
            durationMinutes: durationMinutes
        )
        
        try completionRef.setData(from: completion)
        
        // Update user profile with last completion date and advance day number
        try await updateUserProfile(
            userId: userId,
            currentDayNumber: dayNumber + 1,
            lastCompletionDate: Date()
        )
        
        print("✅ Marked day \(dayNumber) as completed")
    }
    
    /// Get day completions for a program
    func getDayCompletions(userId: String, programId: String) async throws -> [FirestoreDayCompletion] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("completions")
            .whereField("programId", isEqualTo: programId)
            .order(by: "completedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: FirestoreDayCompletion.self)
        }
    }
    
    /// Check if a day was completed today
    func wasDayCompletedToday(userId: String, programId: String) async throws -> Bool {
        guard let profile = try await loadUserProfile(userId: userId),
              let lastCompletion = profile.lastCompletionDate else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(lastCompletion)
    }
    
    /// Get next available day for user (respects calendar-based progression)
    func getNextAvailableDay(userId: String, programId: String) async throws -> Int {
        guard let profile = try await loadUserProfile(userId: userId) else {
            return 1 // Start at day 1 if no profile
        }
        
        let currentDay = profile.currentDayNumber ?? 1
        
        // Check if user completed a day today
        if try await wasDayCompletedToday(userId: userId, programId: programId) {
            // Already completed today, must wait for next calendar day
            return currentDay - 1 // Show the day they just completed
        }
        
        return currentDay
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
