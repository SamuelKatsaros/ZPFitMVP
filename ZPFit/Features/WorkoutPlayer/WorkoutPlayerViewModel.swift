import SwiftUI
import Combine
import AVFoundation

@MainActor
class WorkoutPlayerViewModel: ObservableObject {
    // Data
    let workout: Workout
    private var flatSteps: [WorkoutStep] = []
    
    // State
    @Published var currentStepIndex: Int = 0
    @Published var timeRemaining: Int = 0
    @Published var isPaused: Bool = true
    @Published var isCompleted: Bool = false
    @Published var totalDuration: Int = 0
    
    // Timer
    private var timer: AnyCancellable?
    
    init(workout: Workout) {
        self.workout = workout
        flattenWorkout()
        setupStep()
    }
    
    private func flattenWorkout() {
        // Flatten blocks and steps into a single linear sequence for easier navigation
        // In a real app, we might want to preserve block structure for UI headers
        for block in workout.blocks.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for step in block.steps.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                flatSteps.append(step)
            }
        }
    }
    
    var currentStep: WorkoutStep? {
        guard currentStepIndex < flatSteps.count else { return nil }
        return flatSteps[currentStepIndex]
    }
    
    var nextStep: WorkoutStep? {
        guard currentStepIndex + 1 < flatSteps.count else { return nil }
        return flatSteps[currentStepIndex + 1]
    }
    
    var progress: Double {
        guard !flatSteps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(flatSteps.count)
    }
    
    func setupStep() {
        guard let step = currentStep else {
            completeWorkout()
            return
        }
        
        if let duration = step.durationSeconds {
            timeRemaining = duration
        } else {
            timeRemaining = 0 // Rep based
        }
    }
    
    func togglePause() {
        isPaused.toggle()
        if !isPaused {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    func next() {
        stopTimer()
        if currentStepIndex < flatSteps.count - 1 {
            currentStepIndex += 1
            setupStep()
            // Auto-start next step if it's time-based? Or wait for user?
            // For flow, let's auto-start if it was playing
            if !isPaused {
                startTimer()
            }
        } else {
            completeWorkout()
        }
    }
    
    func previous() {
        stopTimer()
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            setupStep()
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func tick() {
        guard let step = currentStep, step.durationSeconds != nil else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer finished
            // Play sound / haptic
            AudioServicesPlaySystemSound(1005) // System beep
            next()
        }
        
        totalDuration += 1
    }
    
    private func completeWorkout() {
        isCompleted = true
        stopTimer()
    }
}
