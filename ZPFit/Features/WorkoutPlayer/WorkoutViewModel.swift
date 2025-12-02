import Foundation
import SwiftUI
import Combine
import AVKit

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var day: FirestoreProgramDay?
    @Published var exercises: [FirestoreExercise] = []
    @Published var currentExerciseIndex = 0
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private let cloudflareService: CloudflareStreamService
    private let programId: String
    private let dayId: String
    
    init(
        programId: String,
        dayId: String,
        firestoreService: FirestoreService,
        authService: AuthenticationService,
        cloudflareService: CloudflareStreamService
    ) {
        self.programId = programId
        self.dayId = dayId
        self.firestoreService = firestoreService
        self.authService = authService
        self.cloudflareService = cloudflareService
    }
    
    func loadWorkoutData() async {
        isLoading = true
        
        do {
            // Load the day details
            if let loadedDay = try await firestoreService.getProgramDay(programId: programId, dayId: dayId) {
                day = loadedDay
                
                // Convert embedded exercises to FirestoreExercise objects
                let loadedExercises = loadedDay.exercises.enumerated().map { index, embedded -> FirestoreExercise in
                    FirestoreExercise(
                        id: "\(dayId)_\(index)",
                        name: embedded.name,
                        instructions: nil,
                        videoUrl: embedded.videoUrl,
                        thumbnailUrl: embedded.thumbnailUrl,
                        muscleGroup: nil,
                        durationSeconds: nil,
                        reps: embedded.reps,
                        sets: embedded.sets
                    )
                }
                
                await MainActor.run {
                    exercises = loadedExercises
                    isLoading = false
                }
            }
        } catch {
            print("Failed to load workout data: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func getVideoPlayer(for exercise: FirestoreExercise) -> AVPlayer? {
        return cloudflareService.createPlayer(for: exercise.videoURL)
    }
    
    func getThumbnailURL(for exercise: FirestoreExercise) -> URL? {
        return cloudflareService.getThumbnailURL(from: exercise.videoURL)
    }
    
    func markAsFinished() async {
        guard let userId = authService.currentUserId else { return }
        
        let completedExerciseIds = exercises.map { $0.id ?? "" }
        
        do {
            try await firestoreService.saveProgress(
                userId: userId,
                programId: programId,
                dayId: dayId,
                status: .finished,
                exercisesCompleted: completedExerciseIds
            )
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    func markAsSkipped() async {
        guard let userId = authService.currentUserId else { return }
        
        do {
            try await firestoreService.saveProgress(
                userId: userId,
                programId: programId,
                dayId: dayId,
                status: .skipped,
                exercisesCompleted: []
            )
        } catch {
            print("Failed to save skipped status: \(error)")
        }
    }
    
    func updateProgress() {
        guard !exercises.isEmpty else {
            progress = 0
            return
        }
        
        progress = Double(currentExerciseIndex + 1) / Double(exercises.count)
    }
}
