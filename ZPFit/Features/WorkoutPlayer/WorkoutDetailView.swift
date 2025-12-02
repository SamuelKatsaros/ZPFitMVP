import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let workout: Workout?
    let videoURL: URL?
    
    init(workout: Workout? = nil, videoURL: URL? = nil) {
        self.workout = workout
        self.videoURL = videoURL
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Workout Details")
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "heart")
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Hero Video/Image
                            ZStack(alignment: .bottom) {
                                if let videoURL = videoURL {
                                    VideoPlayerView(videoURL: videoURL)
                                        .frame(height: 280)
                                        .cornerRadius(32)
                                } else {
                                    Rectangle()
                                        .fill(Color.ZP.card)
                                        .frame(height: 280)
                                        .cornerRadius(32)
                                        .overlay(
                                            Image(systemName: "figure.strengthtraining.traditional")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                                .opacity(0.3)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        )
                                }
                            }
                            .padding(.top, 20)
                            
                            // Title & Description
                            VStack(alignment: .leading, spacing: 12) {
                                Text(workout?.title ?? "Lower Body Training")
                                    .font(.ZP.largeTitle)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                
                                HStack(spacing: 16) {
                                    Label("\(workout?.durationMinutes ?? 30) min", systemImage: "clock.fill")
                                    Label("Intermediate", systemImage: "chart.bar.fill")
                                    Label("250 cal", systemImage: "flame.fill")
                                }
                                .font(.ZP.subheadline)
                                .foregroundStyle(Color.ZP.textSecondary)
                                
                                Text("Lower body day, let's get that heart rate elevated and burn some calories. For today, you'll need space to run, a resistance band, and some kettle bells.")
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                    .lineLimit(4)
                            }
                            .padding(.horizontal, 20)
                            
                            // Rounds
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Workout Plan")
                                        .font(.ZP.title2)
                                        .foregroundStyle(Color.ZP.textPrimary)
                                    Spacer()
                                    Text("1/\(workout?.blocks.first?.steps.count ?? 8) Exercises")
                                        .font(.ZP.subheadline)
                                        .foregroundStyle(Color.ZP.textSecondary)
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 16) {
                                    RoundRow(title: "Jumping Jacks", duration: "00:30", imageName: "figure.jumping.jacks", isPlaying: true)
                                    RoundRow(title: "Squats", duration: "12 Reps", imageName: "figure.strengthtraining.traditional", isPlaying: false)
                                    RoundRow(title: "Backward Lunge", duration: "10 Reps", imageName: "figure.step.training", isPlaying: false)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
                
                // Bottom Button
                VStack {
                    Spacer()
                    if let workout = workout {
                        NavigationLink(destination: WorkoutPlayerView(workout: workout)) {
                            Text("Start Workout")
                                .primaryButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Increased safe area padding
                    } else {
                        Button(action: {}) {
                            Text("Start Workout")
                                .primaryButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Increased safe area padding
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct RoundRow: View {
    let title: String
    let duration: String?
    let imageName: String
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(isPlaying ? Color.ZP.primary.opacity(0.2) : Color.ZP.cardHover)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: imageName)
                        .font(.title2)
                        .foregroundStyle(isPlaying ? Color.ZP.primary : Color.ZP.textSecondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.ZP.headline)
                    .foregroundStyle(isPlaying ? Color.ZP.primary : Color.ZP.textPrimary)
                if let duration = duration {
                    Text(duration)
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            Spacer()
            
            if isPlaying {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.ZP.primary)
            } else {
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(Color.ZP.textSecondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.ZP.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isPlaying ? Color.ZP.primary.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
