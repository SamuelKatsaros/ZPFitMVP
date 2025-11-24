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
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            } else {
                // Fallback if thumbnail generation fails
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.7))
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
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Generate thumbnail at 1 second into the video
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
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
