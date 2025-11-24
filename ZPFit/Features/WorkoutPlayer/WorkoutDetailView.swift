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
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color.white)
                                .padding()
                        }
                        Spacer()
                        Text("Workout")
                            .font(.ZP.headline)
                            .foregroundStyle(Color.white)
                        Spacer()
                        Color.clear.frame(width: 40, height: 40) // Balance
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Hero Video/Image
                            ZStack(alignment: .bottom) {
                                if let videoURL = videoURL {
                                    VideoPlayerView(videoURL: videoURL)
                                        .frame(height: 300)
                                        .cornerRadius(32)
                                } else {
                                    Rectangle()
                                        .fill(Color.ZP.cardHover)
                                        .frame(height: 300)
                                        .cornerRadius(32)
                                        .overlay(
                                            Image(systemName: "figure.strengthtraining.traditional")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 200)
                                                .opacity(0.5)
                                        )
                                }
                                
                                // Stats Overlay
                                HStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundStyle(.black)
                                            .padding(8)
                                            .background(Color.ZP.accent)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading) {
                                            Text("Time")
                                                .font(.ZP.caption)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                            Text("\(workout?.durationMinutes ?? 30) min")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textPrimary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.ZP.card.opacity(0.8))
                                    .cornerRadius(16)
                                    
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(.black)
                                            .padding(8)
                                            .background(Color.ZP.accent)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading) {
                                            Text("Burn")
                                                .font(.ZP.caption)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                            Text("250 cal")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textPrimary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.ZP.card.opacity(0.8))
                                    .cornerRadius(16)
                                }
                                .offset(y: 30)
                            }
                            .padding(.bottom, 30)
                            
                            // Title & Description
                            VStack(alignment: .leading, spacing: 12) {
                                Text(workout?.title ?? "Lower Body Training")
                                    .font(.ZP.title1)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                
                                Text("Lower body day, let's get that heart rate elevated and burn some calories. For today, you'll need space to run, a resistance band, and some kettle bells. Pace will be fast, but it'll be over quick!")
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                    .lineLimit(4)
                            }
                            .padding(.horizontal)
                            
                            // Rounds
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Rounds")
                                        .font(.ZP.title2)
                                        .foregroundStyle(Color.ZP.textPrimary)
                                    Spacer()
                                    Text("1/\(workout?.blocks.first?.steps.count ?? 8)")
                                        .font(.ZP.subheadline)
                                        .foregroundStyle(Color.ZP.textSecondary)
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    RoundRow(title: "Jumping Jacks", duration: "00:30", imageName: "figure.jumping.jacks", isPlaying: true)
                                    RoundRow(title: "Squats", duration: nil, imageName: "figure.strengthtraining.traditional", isPlaying: false)
                                    RoundRow(title: "Backward Lunge", duration: nil, imageName: "figure.step.training", isPlaying: false)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Button
                VStack {
                    Spacer()
                    if let workout = workout {
                        NavigationLink(destination: WorkoutPlayerView(workout: workout)) {
                            Text("Lets Workout")
                                .font(.ZP.headline)
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ZP.accent)
                                .cornerRadius(32)
                        }
                        .padding()
                    } else {
                        Button(action: {}) {
                            Text("Lets Workout")
                                .font(.ZP.headline)
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ZP.accent)
                                .cornerRadius(32)
                        }
                        .padding()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ZP.cardHover)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: imageName)
                        .font(.title2)
                        .foregroundStyle(Color.ZP.textSecondary)
                )
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textPrimary)
                if let duration = duration {
                    Text(duration)
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title)
                .foregroundStyle(isPlaying ? Color.ZP.accent : Color.ZP.cardHover)
        }
        .padding()
        .background(Color.ZP.card)
        .cornerRadius(16)
    }
}
