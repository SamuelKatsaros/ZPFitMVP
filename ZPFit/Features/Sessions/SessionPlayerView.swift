import SwiftUI
import AVKit

struct SessionPlayerView: View {
    let sessions: [FirestoreSession]
    @State private var currentSessionId: String?
    @Binding var isPresented: Bool
    
    init(sessions: [FirestoreSession], initialSessionId: String, isPresented: Binding<Bool>) {
        self.sessions = sessions
        self._currentSessionId = State(initialValue: initialSessionId)
        self._isPresented = isPresented
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(sessions) { session in
                        SessionVideoPlayer(
                            session: session,
                            isActive: currentSessionId == session.id,
                            isPresented: $isPresented
                        )
                        .containerRelativeFrame(.vertical) // Fixes "half video" issue
                        .id(session.id ?? "")
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentSessionId)
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                // Configure Audio Session
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.duckOthers])
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
    }
}

struct SessionVideoPlayer: View {
    let session: FirestoreSession
    let isActive: Bool
    @Binding var isPresented: Bool
    
    @State private var player: AVPlayer?
    @State private var isMuted: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Video Layer
            if let player = player {
                CustomVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        if isActive {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                    }
                    .onChange(of: isActive) { active in
                        if active {
                            player.seek(to: .zero)
                            player.play()
                        } else {
                            player.pause()
                        }
                    }
            } else {
                Color.black
                ProgressView()
                    .tint(.white)
            }
            
            // 2. Gradient Overlay (Bottom)
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.2),
                    .black.opacity(0.6),
                    .black.opacity(0.8)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            // 3. UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 60) // Safe area adjustment
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom Info Bar
                HStack(alignment: .bottom) {
                    // Left: Title & Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.title)
                            .font(.system(size: 20, weight: .bold)) // Premium font size
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(session.duration) min")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Right: Mute Button
                    Button(action: {
                        isMuted.toggle()
                        player?.isMuted = isMuted
                    }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50) // Bottom safe area
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard player == nil, let url = URL(string: session.videoUrl) else { return }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = isMuted
        self.player = newPlayer
        
        // Loop video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }
    }
}

// Custom Video Player to ensure Aspect Fill
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill // Critical for immersive look
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
