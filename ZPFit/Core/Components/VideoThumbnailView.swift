import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.ZP.card)
                    .overlay(
                        ProgressView()
                            .tint(Color.ZP.primary)
                    )
            } else {
                // Fallback if thumbnail generation fails
                Rectangle()
                    .fill(Color.ZP.cardHover)
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.ZP.textSecondary)
                    )
            }
        }
        .clipped()
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            let asset = AVURLAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Generate thumbnail at 1 second into the video
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            do {
                let (cgImage, _) = try await imageGenerator.image(at: time)
                await MainActor.run {
                    self.thumbnail = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
