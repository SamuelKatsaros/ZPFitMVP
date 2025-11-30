import SwiftUI

struct WorkoutPlayerView: View {
    @StateObject private var viewModel: WorkoutPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(workout: Workout) {
        _viewModel = StateObject(wrappedValue: WorkoutPlayerViewModel(workout: workout))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.ZP.background.ignoresSafeArea()
            
            // Subtle Gradient Overlay
            LinearGradient(
                colors: [Color.ZP.accent.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.ZP.textSecondary)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text(viewModel.workout.title)
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "gear")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.ZP.textSecondary)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(Color.ZP.accent)
                                    .frame(width: geo.size.width * viewModel.progress, height: 6)
                                    .shadow(color: Color.ZP.accent.opacity(0.5), radius: 4, x: 0, y: 0)
                            }
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text("\(Int(viewModel.progress * 100))% Complete")
                                .font(.ZP.caption)
                                .foregroundStyle(Color.ZP.textSecondary)
                            Spacer()
                            Text(formatTime(viewModel.totalDuration))
                                .font(.ZP.caption)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Main Content
                    Spacer()
                    
                    if let step = viewModel.currentStep {
                        VStack(spacing: 40) {
                            // Type Label
                            Text(step.type.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .tracking(2)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(step.type == "rest" ? Color.white.opacity(0.1) : Color.ZP.accent.opacity(0.2))
                                        .stroke(step.type == "rest" ? Color.white.opacity(0.2) : Color.ZP.accent, lineWidth: 1)
                                )
                                .foregroundStyle(step.type == "rest" ? Color.white : Color.ZP.accent)
                            
                            // Exercise Name
                            if let exercise = step.exercise {
                                Text(exercise.name)
                                    .font(.system(size: 36, weight: .bold, design: .default))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                    .padding(.horizontal)
                                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                            } else {
                                Text(step.type == "rest" ? "REST" : "WORK")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.ZP.textPrimary)
                                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            
                            // Timer / Reps
                            if step.durationSeconds != nil {
                                Text(formatTime(viewModel.timeRemaining))
                                    .font(.system(size: 100, weight: .bold, design: .monospaced))
                                    .foregroundStyle(viewModel.timeRemaining <= 3 ? Color.ZP.error : Color.ZP.textPrimary)
                                    .shadow(color: (viewModel.timeRemaining <= 3 ? Color.ZP.error : Color.ZP.accent).opacity(0.3), radius: 20, x: 0, y: 0)
                            } else if let reps = step.reps {
                                VStack(spacing: 8) {
                                    Text("\(reps)")
                                        .font(.system(size: 100, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.ZP.textPrimary)
                                    Text("REPS")
                                        .font(.ZP.title2)
                                        .foregroundStyle(Color.ZP.textSecondary)
                                        .tracking(4)
                                }
                            }
                            
                            // Next Up Preview
                            if let next = viewModel.nextStep {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("NEXT UP")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Color.ZP.textTertiary)
                                        if let nextEx = next.exercise {
                                            Text(nextEx.name)
                                                .font(.ZP.headline)
                                                .foregroundStyle(Color.ZP.textPrimary)
                                                .lineLimit(1)
                                        } else {
                                            Text(next.type.capitalized)
                                                .font(.ZP.headline)
                                                .foregroundStyle(Color.ZP.textPrimary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color.ZP.textTertiary)
                                }
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .background(Color.ZP.card.opacity(0.5))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: viewModel.previous) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundStyle(Color.ZP.textPrimary)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: viewModel.togglePause) {
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.black)
                                .frame(width: 80, height: 80)
                                .background(Color.ZP.accent)
                                .clipShape(Circle())
                                .shadow(color: Color.ZP.accent.opacity(0.4), radius: 15, x: 0, y: 5)
                        }
                        
                        Button(action: viewModel.next) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundStyle(Color.ZP.textPrimary)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
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
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.ZP.accent.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.ZP.accent)
                    .shadow(color: Color.ZP.accent.opacity(0.5), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: 12) {
                Text("Workout Complete!")
                    .font(.ZP.largeTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("You crushed it.")
                    .font(.ZP.title3)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Total Time")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textTertiary)
                    Text("\(duration / 60) min")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ZP.card)
                .cornerRadius(16)
                
                VStack(spacing: 8) {
                    Text("Calories")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textTertiary)
                    Text("320")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ZP.card)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Finish Workout")
                    .font(.ZP.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ZP.accent)
                    .foregroundStyle(Color.ZP.textBlack)
                    .cornerRadius(16)
                    .shadow(color: Color.ZP.accent.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding()
    }
}
