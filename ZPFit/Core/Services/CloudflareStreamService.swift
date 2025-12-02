import Foundation
import AVKit

class CloudflareStreamService {
    
    // MARK: - Video URL Processing
    
    /// Parse Cloudflare Stream URL and return playback URL
    /// Supports formats:
    /// - https://customer-xyz.cloudflarestream.com/abc123/manifest/video.m3u8
    /// - https://cloudflarestream.com/abc123/manifest/video.m3u8
    func getPlaybackURL(from videoURL: String) -> URL? {
        // If it's already a valid manifest URL, return it
        if videoURL.contains("/manifest/video.m3u8") {
            return URL(string: videoURL)
        }
        
        // If it's just a video ID, construct the manifest URL
        // This would require knowing your Cloudflare customer subdomain
        // For now, we'll assume the URL is already properly formatted
        return URL(string: videoURL)
    }
    
    /// Get thumbnail URL for a video
    /// Cloudflare Stream thumbnail format: https://customer-xyz.cloudflarestream.com/{videoId}/thumbnails/thumbnail.jpg
    func getThumbnailURL(from videoURL: String, timestamp: String = "0s") -> URL? {
        // Extract video ID from the URL
        guard let videoId = extractVideoId(from: videoURL) else {
            return URL(string: videoURL) // Return original if can't parse
        }
        
        // Try to construct thumbnail URL
        if let baseURL = extractBaseURL(from: videoURL) {
            let thumbnailURLString = "\(baseURL)/\(videoId)/thumbnails/thumbnail.jpg?time=\(timestamp)"
            return URL(string: thumbnailURLString)
        }
        
        return nil
    }
    
    /// Create AVPlayer for Cloudflare Stream video
    func createPlayer(for videoURL: String) -> AVPlayer? {
        guard let playbackURL = getPlaybackURL(from: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return nil
        }
        
        let playerItem = AVPlayerItem(url: playbackURL)
        let player = AVPlayer(playerItem: playerItem)
        
        // Configure player for optimal streaming
        player.automaticallyWaitsToMinimizeStalling = true
        
        return player
    }
    
    // MARK: - URL Parsing Helpers
    
    private func extractVideoId(from urlString: String) -> String? {
        // Extract video ID from patterns like:
        // https://customer-xyz.cloudflarestream.com/abc123/manifest/video.m3u8
        // Returns: abc123
        
        let components = urlString.components(separatedBy: "/")
        
        // Find the component before "manifest" or "thumbnails"
        if let manifestIndex = components.firstIndex(of: "manifest") {
            guard manifestIndex > 0 else { return nil }
            return components[manifestIndex - 1]
        }
        
        if let thumbnailsIndex = components.firstIndex(of: "thumbnails") {
            guard thumbnailsIndex > 0 else { return nil }
            return components[thumbnailsIndex - 1]
        }
        
        // If it's a simple format like "abc123", return it
        if components.count == 1 {
            return components[0]
        }
        
        return nil
    }
    
    private func extractBaseURL(from urlString: String) -> String? {
        // Extract base URL: https://customer-xyz.cloudflarestream.com
        
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host else {
            return nil
        }
        
        return "\(scheme)://\(host)"
    }
    
    // MARK: - Video Quality
    
    enum VideoQuality: String {
        case auto = "auto"
        case quality1080p = "1080p"
        case quality720p = "720p"
        case quality480p = "480p"
        case quality360p = "360p"
    }
    
    /// Get playback URL with specific quality
    func getPlaybackURL(from videoURL: String, quality: VideoQuality) -> URL? {
        guard let basePlaybackURL = getPlaybackURL(from: videoURL) else {
            return nil
        }
        
        // For auto quality, return the standard manifest
        if quality == .auto {
            return basePlaybackURL
        }
        
        // For specific quality, Cloudflare Stream uses adaptive streaming
        // The manifest handles quality selection automatically
        // This is here for future enhancement if needed
        return basePlaybackURL
    }
    
    // MARK: - Video Metadata
    
    struct VideoMetadata {
        let videoId: String
        let playbackURL: URL
        let thumbnailURL: URL?
        let baseURL: String
    }
    
    /// Extract all relevant metadata from a Cloudflare Stream URL
    func getVideoMetadata(from videoURL: String) -> VideoMetadata? {
        guard let videoId = extractVideoId(from: videoURL),
              let playbackURL = getPlaybackURL(from: videoURL),
              let baseURL = extractBaseURL(from: videoURL) else {
            return nil
        }
        
        let thumbnailURL = getThumbnailURL(from: videoURL)
        
        return VideoMetadata(
            videoId: videoId,
            playbackURL: playbackURL,
            thumbnailURL: thumbnailURL,
            baseURL: baseURL
        )
    }
    
    // MARK: - Error Handling
    
    enum CloudflareStreamError: LocalizedError {
        case invalidURL
        case invalidVideoId
        case playbackFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid video URL format"
            case .invalidVideoId:
                return "Could not extract video ID"
            case .playbackFailed:
                return "Video playback failed"
            }
        }
    }
}
