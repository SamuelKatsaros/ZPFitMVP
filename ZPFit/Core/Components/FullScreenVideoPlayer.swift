import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    let videoURL: URL
    let exercise: FirestoreProgramDay.EmbeddedExercise
    @Environment(\.dismiss) private var dismiss
    
    // Player State
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isPlaying = true
    @State private var isMuted = false
    @State private var showControls = true
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    
    // Timer for hiding controls
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Layer
            if let player = player {
                AVPlayerControllerView(player: player)
                    .ignoresSafeArea()
                    .overlay(
                        Color.black.opacity(0.001) // Transparent overlay to catch taps
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showControls.toggle()
                                    if showControls {
                                        startControlsTimer()
                                    }
                                }
                            }
                    )
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Controls Overlay
            if showControls {
                // Gradient Backgrounds for readability
                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .ignoresSafeArea()
                    
                    Spacer()
                    
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .ignoresSafeArea()
                }
                .allowsHitTesting(false)
                
                // UI Elements
                VStack {
                    // Top Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        }) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Center Play/Pause (Large)
                    Button(action: {
                        togglePlayPause()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                            .opacity(showControls ? 1 : 0)
                    }
                    
                    Spacer()
                    
                    // Bottom Info & Progress
                    VStack(alignment: .leading, spacing: 16) {
                        // Exercise Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 12) {
                                if let sets = exercise.sets {
                                    Label("\(sets) Sets", systemImage: "arrow.triangle.2.circlepath")
                                }
                                if let reps = exercise.reps {
                                    Label("\(reps) Reps", systemImage: "repeat")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        // Progress Bar
                        if duration > 0 {
                            HStack(spacing: 12) {
                                Text(formatTime(progress))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: 4)
                                            .cornerRadius(2)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * (progress / duration), height: 4)
                                            .cornerRadius(2)
                                    }
                                }
                                .frame(height: 4)
                                
                                Text(formatTime(duration))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            setupPlayer()
            startControlsTimer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        player = queuePlayer
        
        // Observe duration
        Task {
            if let duration = try? await playerItem.asset.load(.duration) {
                await MainActor.run {
                    self.duration = CMTimeGetSeconds(duration)
                }
            }
        }
        
        // Observe progress
        queuePlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            self.progress = CMTimeGetSeconds(time)
        }
        
        queuePlayer.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        looper = nil
        controlsTimer?.invalidate()
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        
        // Reset timer when interacting
        startControlsTimer()
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                if isPlaying {
                    showControls = false
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper for AVPlayerLayer
struct AVPlayerControllerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { }
}
