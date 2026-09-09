import Foundation
import AVFoundation
import CoreImage
import CoreVideo
import VideoToolbox
import AppKit

public final class FrameInterpolationEngine {
    public static let shared = FrameInterpolationEngine()
    
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var currentProgress: Double = 0.0
    @Published public private(set) var statusText: String = "Готов"
    
    private var isCancelled: Bool = false
    
    // Unified Rec.709 color space to prevent any gamma or luma jumping
    private let rec709ColorSpace = CGColorSpace(name: CGColorSpace.itur_709)!
    private lazy var ciContext: CIContext = {
        CIContext(options: [
            .workingColorSpace: rec709ColorSpace,
            .outputColorSpace: rec709ColorSpace,
            .useSoftwareRenderer: false
        ])
    }()
    
    private init() {}
    
    public func pause() {
        isPaused = true
        statusText = "Приостановлено"
    }
    
    public func resume() {
        isPaused = false
        statusText = "Возобновление..."
    }
    
    public func cancel() {
        isCancelled = true
        isPaused = false
        statusText = "Отмена..."
    }
    
    public func processVideo(
        item: VideoItem,
        speedFactor: Double,
        targetFps: Int,
        motionBlur: Double,
        quality: ProcessingQuality,
        format: ExportFormat,
        memoryLimitMB: Int,
        isSegmentOnly: Bool = false,
        outputURL: URL,
        onProgress: @escaping (Double, String) -> Void
    ) async throws {
        isProcessing = true
        isPaused = false
        isCancelled = false
        currentProgress = 0.0
        statusText = "Инициализация конвейера..."
        
        defer {
            isProcessing = false
            isPaused = false
        }
        
        let asset = AVURLAsset(url: item.url)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw NSError(domain: "MoviaEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Видеодорожка не найдена"])
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let totalDuration = try await asset.load(.duration).seconds
        let sourceFpsVal = try await videoTrack.load(.nominalFrameRate)
        let sourceFps = sourceFpsVal > 0 ? Double(sourceFpsVal) : 30.0
        
        var outputSize = naturalSize
        if abs(preferredTransform.b) == 1.0 && abs(preferredTransform.c) == 1.0 {
            outputSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        }
        
        let effectiveTrimStart = max(0.0, item.trimStart)
        let effectiveTrimEnd = min(totalDuration, item.trimEnd > item.trimStart ? item.trimEnd : totalDuration)
        
        // Clean previous output file
        try? FileManager.default.removeItem(at: outputURL)
        
        // 1. Setup AVAssetReader with alwaysCopiesSampleData = true
        let reader = try AVAssetReader(asset: asset)
        if isSegmentOnly {
            let startSec = max(0.0, effectiveTrimStart - 0.1)
            let durSec = max(0.1, (effectiveTrimEnd - startSec) + 0.1)
            reader.timeRange = CMTimeRange(
                start: CMTime(seconds: startSec, preferredTimescale: 600),
                duration: CMTime(seconds: durSec, preferredTimescale: 600)
            )
        }
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        readerOutput.alwaysCopiesSampleData = true // CRITICAL: Prevents buffer recycling in place
        if reader.canAdd(readerOutput) {
            reader.add(readerOutput)
        }
        
        // 2. Setup AVAssetWriter
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: (format == .proRes422HQ || format == .proRes422) ? .mov : .mp4)
        
        // Calculate intelligent adaptive bitrate matching the source video
        let srcRate = try? await videoTrack.load(.estimatedDataRate)
        let sourceBitrate: Double
        if let r = srcRate, r > 1_000_000 {
            sourceBitrate = Double(r)
        } else {
            // Sensible standard bitrates: 1080p ~10 Mbps, 4K ~24 Mbps
            let pixelCount = outputSize.width * outputSize.height
            sourceBitrate = pixelCount > 3_000_000 ? 24_000_000 : 10_000_000
        }
        
        var compressionProps: [String: Any] = [:]
        let codec: AVVideoCodecType
        switch format {
        case .proRes422HQ:
            codec = .proRes422HQ
        case .proRes422:
            codec = .proRes422
        case .hevc:
            codec = .hevc
            compressionProps[AVVideoProfileLevelKey] = kVTProfileLevel_HEVC_Main_AutoLevel
            // HEVC achieves identical quality at 30-40% lower bitrate
            compressionProps[AVVideoAverageBitRateKey] = Int(min(max(sourceBitrate * 0.75, 5_000_000), 16_000_000))
            compressionProps[AVVideoMaxKeyFrameIntervalKey] = targetFps
            compressionProps[AVVideoAllowFrameReorderingKey] = false // Strict monotonic frames
        case .h264:
            codec = .h264
            compressionProps[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
            // Adaptive H.264 bitrate
            compressionProps[AVVideoAverageBitRateKey] = Int(min(max(sourceBitrate, 7_000_000), 18_000_000))
            compressionProps[AVVideoMaxKeyFrameIntervalKey] = targetFps
            compressionProps[AVVideoAllowFrameReorderingKey] = false // Strict monotonic frames
        }
        
        // Strict Color Tagging matching Rec.709
        let colorProps: [String: Any] = [
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
        ]
        
        var writerOutputSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: Int(outputSize.width),
            AVVideoHeightKey: Int(outputSize.height),
            AVVideoColorPropertiesKey: colorProps
        ]
        if !compressionProps.isEmpty {
            writerOutputSettings[AVVideoCompressionPropertiesKey] = compressionProps
        }
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: writerOutputSettings)
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = preferredTransform
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(outputSize.width),
            kCVPixelBufferHeightKey as String: Int(outputSize.height),
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        if writer.canAdd(writerInput) {
            writer.add(writerInput)
        }
        
        guard reader.startReading() else {
            throw reader.error ?? NSError(domain: "MoviaEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка старта чтения"])
        }
        
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "MoviaEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ошибка старта записи"])
        }
        
        writer.startSession(atSourceTime: .zero)
        
        // Strict integer-based monotonic PTS generator to prevent any timestamp jitter
        var outputFrameIndex: Int64 = 0
        let timescale: CMTimeScale = CMTimeScale(1000 * targetFps)
        
        func writeCIImage(_ img: CIImage) {
            while !writerInput.isReadyForMoreMediaData && !isCancelled {
                usleep(2000)
            }
            guard !isCancelled, let pool = adaptor.pixelBufferPool else { return }
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
            guard status == kCVReturnSuccess, let buf = pixelBuffer else { return }
            
            // Render with exact Rec.709 color profile
            ciContext.render(img, to: buf, bounds: CGRect(origin: .zero, size: outputSize), colorSpace: rec709ColorSpace)
            
            let pts = CMTime(value: outputFrameIndex * 1000, timescale: timescale)
            while !writerInput.isReadyForMoreMediaData && !isCancelled {
                usleep(1000)
            }
            _ = adaptor.append(buf, withPresentationTime: pts)
            outputFrameIndex += 1
        }
        
        // Multiplier: how many output frames to generate per input frame interval
        let interpolationSteps = max(1, Int(speedFactor.rounded()))
        
        var prevImage: CIImage? = nil
        var sourceFramesProcessed = 0
        
        while !isCancelled {
            // Check pause
            while isPaused && !isCancelled {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            
            // Thermal throttling protection
            if ThermalMonitor.shared.isThrottled {
                try await Task.sleep(nanoseconds: 12_000_000)
            }
            
            guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                break
            }
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }
            
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            sourceFramesProcessed += 1
            
            let progress: Double
            if isSegmentOnly {
                let segDur = max(0.05, effectiveTrimEnd - effectiveTrimStart)
                progress = min(0.99, max(0.0, (pts - effectiveTrimStart) / segDur))
            } else {
                progress = totalDuration > 0 ? min(0.99, pts / totalDuration) : 0.0
            }
            await MainActor.run {
                self.currentProgress = progress
                self.statusText = String(format: "Обработка кадров... %.0f%%", progress * 100)
                onProgress(progress, self.statusText)
            }
            
            let currentImage = CIImage(cvPixelBuffer: imageBuffer)
            let inSegment = (pts >= effectiveTrimStart && pts <= effectiveTrimEnd)
            
            if inSegment {
                // SLOW MOTION SEGMENT: interpolate intermediate frames between prev and current
                if let prev = prevImage, interpolationSteps > 1 {
                    for step in 1..<interpolationSteps {
                        let weight = Double(step) / Double(interpolationSteps)
                        
                        let blended: CIImage
                        if motionBlur > 0.05 {
                            // Temporal Motion Blur: multi-sample blend between adjacent sub-frames
                            let mbSpread = motionBlur * 0.15
                            let subWeight1 = max(0.0, weight - mbSpread)
                            let subWeight2 = min(1.0, weight + mbSpread)
                            
                            let f1 = CIFilter(name: "CIDissolveTransition")!
                            f1.setValue(prev, forKey: kCIInputImageKey)
                            f1.setValue(currentImage, forKey: kCIInputTargetImageKey)
                            f1.setValue(subWeight1, forKey: kCIInputTimeKey)
                            
                            let f2 = CIFilter(name: "CIDissolveTransition")!
                            f2.setValue(prev, forKey: kCIInputImageKey)
                            f2.setValue(currentImage, forKey: kCIInputTargetImageKey)
                            f2.setValue(subWeight2, forKey: kCIInputTimeKey)
                            
                            let fBlend = CIFilter(name: "CIDissolveTransition")!
                            fBlend.setValue(f1.outputImage ?? currentImage, forKey: kCIInputImageKey)
                            fBlend.setValue(f2.outputImage ?? currentImage, forKey: kCIInputTargetImageKey)
                            fBlend.setValue(0.5, forKey: kCIInputTimeKey)
                            blended = fBlend.outputImage ?? currentImage
                        } else {
                            // Clean optical linear dissolve
                            let filter = CIFilter(name: "CIDissolveTransition")!
                            filter.setValue(prev, forKey: kCIInputImageKey)
                            filter.setValue(currentImage, forKey: kCIInputTargetImageKey)
                            filter.setValue(weight, forKey: kCIInputTimeKey)
                            blended = filter.outputImage ?? currentImage
                        }
                        
                        writeCIImage(blended)
                    }
                }
                
                // Write current frame with the EXACT same Rec.709 rendering pipeline
                writeCIImage(currentImage)
            } else {
                if isSegmentOnly {
                    if pts > effectiveTrimEnd {
                        break // Finished target segment!
                    }
                    prevImage = currentImage
                    continue
                }
                
                // OUTSIDE SEGMENT: normal real-time playback
                writeCIImage(currentImage)
                
                // If target FPS is higher than source FPS, duplicate frame to maintain real-time speed
                let ratio = Int((Double(targetFps) / sourceFps).rounded())
                if ratio > 1 {
                    for _ in 1..<ratio {
                        writeCIImage(currentImage)
                    }
                }
            }
            
            prevImage = currentImage
        }
        
        if isCancelled {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw NSError(domain: "MoviaEngine", code: 99, userInfo: [NSLocalizedDescriptionKey: "Операция отменена пользователем"])
        }
        
        writerInput.markAsFinished()
        await writer.finishWriting()
        
        await MainActor.run {
            self.currentProgress = 1.0
            self.statusText = "Готово"
            onProgress(1.0, "Готово")
        }
    }
}
