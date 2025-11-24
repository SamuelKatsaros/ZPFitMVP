import SwiftUI

struct WorkoutPlayerView: View {
    @StateObject private var viewModel: WorkoutPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(workout: Workout) {
        _viewModel = StateObject(wrappedValue: WorkoutPlayerViewModel(workout: workout))
    }
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            if viewModel.isCompleted {
                WorkoutSummaryView(duration: viewModel.totalDuration) {
                    dismiss()
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.ZP.textPrimary)
                                .padding()
                        }
                        Spacer()
                        Text(viewModel.workout.title)
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "gear") // Settings placeholder
                                .foregroundStyle(Color.ZP.textPrimary)
                                .padding()
                        }
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.ZP.card)
                                .frame(height: 4)
                            Rectangle()
                                .fill(Color.ZP.accent)
                                .frame(width: geo.size.width * viewModel.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // Main Content
                    Spacer()
                    
                    if let step = viewModel.currentStep {
                        VStack(spacing: 30) {
                            // Type Label
                            Text(step.type.uppercased())
                                .font(.ZP.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(step.type == "rest" ? Color.ZP.card : Color.ZP.accent)
                                .foregroundStyle(step.type == "rest" ? Color.ZP.textSecondary : Color.ZP.textBlack)
                                .cornerRadius(8)
                            
                            // Exercise Name
                            if let exercise = step.exercise {
                                Text(exercise.name)
                                    .font(.ZP.display)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                    .padding(.horizontal)
                            } else {
                                Text(step.type == "rest" ? "Rest" : "Work")
                                    .font(.ZP.display)
                                    .foregroundStyle(Color.ZP.textPrimary)
                            }
                            
                            // Timer / Reps
                            if step.durationSeconds != nil {
                                Text(formatTime(viewModel.timeRemaining))
                                    .font(.system(size: 90, weight: .bold, design: .monospaced))
                                    .foregroundStyle(viewModel.timeRemaining <= 3 ? Color.ZP.error : Color.ZP.textPrimary)
                            } else if let reps = step.reps {
                                Text("\(reps) Reps")
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundStyle(Color.ZP.textPrimary)
                            }
                            
                            // Next Up Preview
                            if let next = viewModel.nextStep {
                                VStack(spacing: 4) {
                                    Text("NEXT UP")
                                        .font(.ZP.caption)
                                        .foregroundStyle(Color.ZP.textTertiary)
                                    if let nextEx = next.exercise {
                                        Text(nextEx.name)
                                            .font(.ZP.subheadline)
                                            .foregroundStyle(Color.ZP.textSecondary)
                                    } else {
                                        Text(next.type.capitalized)
                                            .font(.ZP.subheadline)
                                            .foregroundStyle(Color.ZP.textSecondary)
                                    }
                                }
                                .padding()
                                .background(Color.ZP.card.opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: viewModel.previous) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundStyle(Color.ZP.textPrimary)
                        }
                        
                        Button(action: viewModel.togglePause) {
                            Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.ZP.accent)
                        }
                        
                        Button(action: viewModel.next) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundStyle(Color.ZP.textPrimary)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct WorkoutSummaryView: View {
    let duration: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ZP.accent)
            
            Text("Workout Complete!")
                .font(.ZP.display)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Text("You crushed it.")
                .font(.ZP.title3)
                .foregroundStyle(Color.ZP.textSecondary)
            
            VStack(spacing: 8) {
                Text("Total Time")
                    .font(.ZP.caption)
                    .foregroundStyle(Color.ZP.textTertiary)
                Text("\(duration / 60) min")
                    .font(.ZP.title1)
                    .foregroundStyle(Color.ZP.textPrimary)
            }
            .padding()
            .background(Color.ZP.card)
            .cornerRadius(16)
            
            Button(action: onDismiss) {
                Text("Finish")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ZP.accent)
                    .foregroundStyle(Color.ZP.textBlack)
                    .shadow(color: Color.ZP.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}
