import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Close Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding()
            }
            .padding(.top, 40) // Adjust for safe area if needed, though ignoresSafeArea usually handles it well enough for overlays
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
