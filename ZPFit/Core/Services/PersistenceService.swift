import Foundation
import SwiftData
import Combine

@MainActor
class PersistenceService: ObservableObject {
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                UserProfile.self,
                Trainer.self,
                Program.self,
                Workout.self,
                WorkoutBlock.self,
                WorkoutStep.self,
                Exercise.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Check if seeding is needed
            seedDataIfNeeded()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func seedDataIfNeeded() {
        let context = container.mainContext
        
        // Check if we already have a trainer
        let descriptor = FetchDescriptor<Trainer>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            print("Seeding data...")
            loadSeedData(context: context)
        }
    }
    
    private func loadSeedData(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "SeedData", withExtension: "json") else {
            // Fallback for development if bundle resource isn't found (e.g. in preview or raw run)
            // In a real app, ensure the file is in the bundle.
            // For this environment, we might need to read from the file system directly if Bundle fails?
            // But Bundle.main should work if added to target.
            // I'll add a fallback to read from the known path for this agent environment if needed,
            // but standard Bundle is best.
            print("SeedData.json not found in Bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let seed = try decoder.decode(SeedDataPayload.self, from: data)
            
            // 1. Create Exercises
            var exerciseMap: [String: Exercise] = [:]
            for exData in seed.exercises {
                let exercise = Exercise(
                    id: exData.id,
                    name: exData.name,
                    instructions: exData.instructions,
                    videoURL: exData.videoURL,
                    thumbnailURL: exData.thumbnailURL,
                    muscleGroup: exData.muscleGroup
                )
                context.insert(exercise)
                exerciseMap[exData.id] = exercise
            }
            
            // 2. Create Trainer
            let trainer = Trainer(
                id: seed.trainer.id,
                name: seed.trainer.name,
                bio: seed.trainer.bio,
                imageURL: seed.trainer.imageURL
            )
            context.insert(trainer)
            
            // 3. Create Programs & Workouts
            for progData in seed.programs {
                let program = Program(
                    id: progData.id,
                    title: progData.title,
                    subtitle: progData.subtitle,
                    difficulty: progData.difficulty,
                    durationWeeks: progData.durationWeeks,
                    coverImage: progData.coverImage
                )
                program.trainer = trainer
                context.insert(program)
                
                for woData in progData.workouts {
                    let workout = Workout(
                        id: woData.id,
                        title: woData.title,
                        type: woData.type,
                        durationMinutes: woData.durationMinutes,
                        difficulty: woData.difficulty
                    )
                    workout.program = program
                    context.insert(workout)
                    
                    for blockData in woData.blocks {
                        let block = WorkoutBlock(title: blockData.title, orderIndex: blockData.orderIndex)
                        block.workout = workout
                        context.insert(block)
                        
                        for (stepIndex, stepData) in blockData.steps.enumerated() {
                            let step = WorkoutStep(
                                orderIndex: stepIndex,
                                type: stepData.type,
                                durationSeconds: stepData.durationSeconds,
                                reps: stepData.reps,
                                sets: stepData.sets
                            )
                            step.block = block
                            
                            if let exId = stepData.exerciseId, let exercise = exerciseMap[exId] {
                                step.exercise = exercise
                            }
                            context.insert(step)
                        }
                    }
                }
            }
            
            try context.save()
            print("Seeding complete.")
            
        } catch {
            print("Failed to seed data: \(error)")
        }
    }
}

// MARK: - Intermediate Codable Structs
private struct SeedDataPayload: Codable {
    let trainer: TrainerData
    let programs: [ProgramData]
    let exercises: [ExerciseData]
}

private struct TrainerData: Codable {
    let id, name, bio, imageURL: String
}

private struct ProgramData: Codable {
    let id, title, subtitle, difficulty: String
    let durationWeeks: Int
    let coverImage: String
    let workouts: [WorkoutData]
}

private struct WorkoutData: Codable {
    let id, title, type: String
    let durationMinutes: Int
    let difficulty: String
    let blocks: [BlockData]
}

private struct BlockData: Codable {
    let title: String
    let orderIndex: Int
    let steps: [StepData]
}

private struct StepData: Codable {
    let type: String
    let durationSeconds: Int?
    let reps: Int?
    let sets: Int?
    let exerciseId: String?
}

private struct ExerciseData: Codable {
    let id, name, instructions, videoURL, thumbnailURL, muscleGroup: String
}
