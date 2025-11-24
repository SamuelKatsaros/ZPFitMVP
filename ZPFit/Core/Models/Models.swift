import Foundation
import SwiftData

// MARK: - User
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var experienceLevel: String // Beginner, Intermediate, Advanced
    var goal: String // Fat Loss, Muscle, etc.
    var joinedDate: Date
    
    // Relationships
    var activeProgram: Program?
    
    init(id: UUID = UUID(), name: String = "", experienceLevel: String = "Intermediate", goal: String = "General Fitness") {
        self.id = id
        self.name = name
        self.experienceLevel = experienceLevel
        self.goal = goal
        self.joinedDate = Date()
    }
}

// MARK: - Trainer
@Model
final class Trainer {
    @Attribute(.unique) var id: String
    var name: String
    var bio: String
    var imageURL: String
    
    @Relationship(deleteRule: .cascade) var programs: [Program] = []
    
    init(id: String, name: String, bio: String, imageURL: String) {
        self.id = id
        self.name = name
        self.bio = bio
        self.imageURL = imageURL
    }
}

// MARK: - Program
@Model
final class Program {
    @Attribute(.unique) var id: String
    var title: String
    var subtitle: String
    var difficulty: String
    var durationWeeks: Int
    var coverImage: String
    
    // Relationships
    var trainer: Trainer?
    @Relationship(deleteRule: .cascade) var workouts: [Workout] = []
    
    init(id: String, title: String, subtitle: String, difficulty: String, durationWeeks: Int, coverImage: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.difficulty = difficulty
        self.durationWeeks = durationWeeks
        self.coverImage = coverImage
    }
}

// MARK: - Workout
@Model
final class Workout {
    @Attribute(.unique) var id: String
    var title: String
    var type: String // HIIT, Strength, Cardio
    var durationMinutes: Int
    var difficulty: String
    
    // Relationships
    var program: Program?
    @Relationship(deleteRule: .cascade) var blocks: [WorkoutBlock] = []
    
    init(id: String, title: String, type: String, durationMinutes: Int, difficulty: String) {
        self.id = id
        self.title = title
        self.type = type
        self.durationMinutes = durationMinutes
        self.difficulty = difficulty
    }
}

// MARK: - Workout Block (e.g. Warmup, Main Set)
@Model
final class WorkoutBlock {
    var id: UUID
    var title: String
    var orderIndex: Int
    
    // Relationships
    var workout: Workout?
    @Relationship(deleteRule: .cascade) var steps: [WorkoutStep] = []
    
    init(id: UUID = UUID(), title: String, orderIndex: Int) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
    }
}

// MARK: - Workout Step (Exercise + Parameters)
@Model
final class WorkoutStep {
    var id: UUID
    var orderIndex: Int
    var type: String // work, rest
    var durationSeconds: Int?
    var reps: Int?
    var sets: Int?
    
    // Relationships
    var block: WorkoutBlock?
    var exercise: Exercise?
    
    init(id: UUID = UUID(), orderIndex: Int, type: String, durationSeconds: Int? = nil, reps: Int? = nil, sets: Int? = nil) {
        self.id = id
        self.orderIndex = orderIndex
        self.type = type
        self.durationSeconds = durationSeconds
        self.reps = reps
        self.sets = sets
    }
}

// MARK: - Exercise
@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var instructions: String
    var videoURL: String
    var thumbnailURL: String
    var muscleGroup: String
    
    init(id: String, name: String, instructions: String, videoURL: String, thumbnailURL: String, muscleGroup: String) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.muscleGroup = muscleGroup
    }
}
