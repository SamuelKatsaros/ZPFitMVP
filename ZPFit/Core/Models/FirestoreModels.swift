import Foundation
import FirebaseFirestore

// MARK: - Firestore Program
struct FirestoreProgram: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String  // Changed from 'title'
    var description: String  // Changed from 'subtitle'
    var thumbnailUrl: String  // Changed from 'coverImage'
    var createdAt: String?
    var difficulty: String?  // Now reading from Firestore
    
    // Computed properties for compatibility with existing UI
    var title: String { name }
    var subtitle: String { description }
    var coverImage: String { thumbnailUrl }
    var durationWeeks: Int { 12 }  // Default since not in your schema
    var trainerId: String? { nil }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case thumbnailUrl
        case createdAt
        case difficulty
    }
    
    // Convert to local Program model
    func toProgram() -> Program {
        Program(
            id: id ?? UUID().uuidString,
            title: name,
            subtitle: description,
            difficulty: difficulty ?? "Intermediate",
            durationWeeks: durationWeeks,
            coverImage: thumbnailUrl
        )
    }
}

// MARK: - Firestore Program Day
struct FirestoreProgramDay: Codable, Identifiable {
    @DocumentID var id: String?
    var dayNumber: Int
    var title: String
    var description: String
    var thumbnailUrl: String?
    var exercises: [EmbeddedExercise]  // Changed from exerciseIds
    
    // Computed property for backward compatibility
    var exerciseIds: [String] {
        exercises.enumerated().map { "\(id ?? "day")_exercise_\($0.offset)" }
    }
    
    var difficulty: String?
    var duration: Int?
    
    var durationMinutes: Int {
        // Use fetched duration if available, otherwise estimate
        if let duration = duration {
            return duration
        }
        return exercises.count * 5  // ~5 min per exercise
    }
    
    var type: String? { title }
    
    enum CodingKeys: String, CodingKey {
        case id
        case dayNumber
        case title
        case description
        case thumbnailUrl
        case exercises
        case difficulty
        case duration
    }
    
    // Embedded exercise structure matching your Firestore
    struct EmbeddedExercise: Codable {
        var name: String
        var reps: Int?
        var sets: Int?
        var videoUrl: String?
        var thumbnailUrl: String?
    }
}

// MARK: - Firestore Exercise
struct FirestoreExercise: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var instructions: String?
    var videoUrl: String?  // Changed from 'videoURL'
    var thumbnailUrl: String?  // Changed from 'thumbnailURL'
    var muscleGroup: String?
    var durationSeconds: Int?
    var reps: Int?
    var sets: Int?
    
    // Computed properties for compatibility
    var videoURL: String { videoUrl ?? "" }
    var thumbnailURL: String { thumbnailUrl ?? "" }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case instructions
        case videoUrl
        case thumbnailUrl
        case muscleGroup
        case durationSeconds
        case reps
        case sets
    }
    
    // Convert to local Exercise model
    func toExercise() -> Exercise {
        Exercise(
            id: id ?? UUID().uuidString,
            name: name,
            instructions: instructions ?? "",
            videoURL: videoUrl ?? "",
            thumbnailURL: thumbnailUrl ?? "",
            muscleGroup: muscleGroup ?? "General"
        )
    }
}

// MARK: - Firestore User Progress
struct FirestoreUserProgress: Codable {
    @DocumentID var id: String?
    var dayId: String
    var programId: String
    var status: ProgressStatus
    var completedAt: Date
    var exercisesCompleted: [String]
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case dayId
        case programId
        case status
        case completedAt
        case exercisesCompleted
        case notes
    }
}

// MARK: - Progress Status
enum ProgressStatus: String, Codable {
    case finished
    case skipped
    case inProgress = "in_progress"
}

// MARK: - Firestore User Profile
struct FirestoreUserProfile: Codable {
    @DocumentID var id: String?
    var email: String?
    var name: String?
    var currentProgramId: String?
    var currentDayNumber: Int?
    var joinedDate: Date?
    var experienceLevel: String?
    var goal: String?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case currentProgramId
        case currentDayNumber
        case joinedDate
        case experienceLevel
        case goal
        case updatedAt
    }
}

struct FirestoreTrainer: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var bio: String
    var imageURL: String
    var specialties: [String]?
    
    // Convert to local Trainer model
    func toTrainer() -> Trainer {
        Trainer(
            id: id ?? UUID().uuidString,
            name: name,
            bio: bio,
            imageURL: imageURL
        )
    }
}

// MARK: - Firestore Session
struct FirestoreSession: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var duration: Int  // in minutes
    var videoUrl: String
    var thumbnailUrl: String
    var createdAt: String?
    var order: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case duration
        case videoUrl
        case thumbnailUrl
        case createdAt
        case order
    }
}

