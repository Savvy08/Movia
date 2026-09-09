import Foundation
import AVFoundation
import AppKit

public final class FilmstripGenerator {
    public static let shared = FilmstripGenerator()
    
    private init() {}
    
    public func generateFilmstrip(for url: URL, count: Int = 12) async -> [NSImage] {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration).seconds, duration > 0 else {
            return []
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 160, height: 90) // Lightweight thumbnails
        
        var images: [NSImage] = []
        let step = duration / Double(count)
        
        for i in 0..<count {
            let timeSeconds = min(duration - 0.05, max(0.0, Double(i) * step))
            let cmTime = CMTime(seconds: timeSeconds, preferredTimescale: 600)
            if let cgImage = try? generator.copyCGImage(at: cmTime, actualTime: nil) {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                images.append(nsImage)
            }
        }
        
        return images
    }
}
