import Foundation
import AVFoundation
import AppKit

public enum VideoMetadataExtractor {
    public static func extractMetadata(from url: URL) async throws -> VideoItem {
        let asset = AVURLAsset(url: url)
        
        let duration = try await asset.load(.duration).seconds
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        var resolution: CGSize = .zero
        var nominalFps: Double = 30.0
        
        if let videoTrack = tracks.first {
            let naturalSize = try await videoTrack.load(.naturalSize)
            let transform = try await videoTrack.load(.preferredTransform)
            
            // Check if video is rotated (portrait)
            if abs(transform.b) == 1.0 && abs(transform.c) == 1.0 {
                resolution = CGSize(width: naturalSize.height, height: naturalSize.width)
            } else {
                resolution = naturalSize
            }
            
            let fps = try await videoTrack.load(.nominalFrameRate)
            if fps > 0 {
                nominalFps = Double(fps)
            }
        }
        
        // File size
        var fileSizeStr = "0 МБ"
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            let mb = Double(size) / (1024.0 * 1024.0)
            if mb >= 1024.0 {
                fileSizeStr = String(format: "%.1f ГБ", mb / 1024.0)
            } else {
                fileSizeStr = String(format: "%.0f МБ", mb)
            }
        }
        
        // Thumbnail
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 480, height: 270)
        
        var thumbnail: NSImage? = nil
        let time = CMTime(seconds: min(1.0, max(0.0, duration / 2.0)), preferredTimescale: 600)
        if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
            thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        
        var item = VideoItem(
            url: url,
            name: url.lastPathComponent,
            duration: duration,
            resolution: resolution,
            sourceFps: nominalFps,
            fileSizeString: fileSizeStr,
            thumbnail: thumbnail
        )
        item.trimStart = 0.0
        item.trimEnd = duration
        return item
    }
}
