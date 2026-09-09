import Foundation
import SwiftUI
import AppKit
import AVFoundation

@MainActor
public final class AppState: ObservableObject {
    // Navigation
    @Published public var currentTab: NavTab = .home
    @Published public var selectedSidebarItem: SidebarItem = .project
    
    // Video Queue
    @Published public var queue: [VideoItem] = []
    @Published public var activeIndex: Int = -1
    
    public var activeItem: VideoItem? {
        guard !queue.isEmpty, activeIndex >= 0, activeIndex < queue.count else { return nil }
        return queue[activeIndex]
    }
    
    // Video Player
    @Published public var player: AVPlayer = AVPlayer()
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var totalDuration: Double = 0.0
    @Published public var processedURL: URL? = nil
    private var timeObserverToken: Any?
    
    // Slow Motion Controls
    @Published public var speedPreset: SlowdownPreset = .custom
    @Published public var customSpeed: Double = 4.0 // 1.5x ... 16x
    @Published public var targetFps: TargetFPS = .fps60
    @Published public var motionBlur: Double = 0.5 // 0.0 to 1.0 (Off to High)
    
    // Timeline Segment (In / Out)
    @Published public var trimStart: Double = 0.0
    @Published public var trimEnd: Double = 0.0
    @Published public var timelineZoom: Double = 1.0 // 1.0x to 8.0x
    @Published public var filmstripImages: [NSImage] = []
    @Published public var isSegmentOnlyExport: Bool = false
    
    // Preview Mode
    @Published public var previewMode: PreviewMode = .original
    @Published public var splitPosition: CGFloat = 0.5 // 0.0 to 1.0
    @Published public var previewQuality: PreviewQuality = .draft720p
    
    // Quality & Hardware Engine
    @Published public var processingQuality: ProcessingQuality = .balanced
    @Published public var memoryLimit: MemoryLimitOption = .mb300
    @Published public var exportFormat: ExportFormat = .proRes422HQ
    @Published public var quickExportProfile: QuickExportProfile = .bestQuality
    @Published public var isThermalProtectionEnabled: Bool = true
    
    // Processing Engine State
    @Published public var isProcessing: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var statusMessage: String = "Готов к обработке"
    
    // History & Presets
    @Published public var history: [HistoryItem] = []
    @Published public var customPresets: [SlowMoPreset] = []
    
    // Thermal & Hardware monitor
    @ObservedObject public var thermalMonitor = ThermalMonitor.shared
    
    public init() {
        loadHistory()
        loadPresets()
    }
    
    // MARK: - Video Import
    public func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie, .mpeg4Movie, .avi]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Выберите видеофайл для создания замедления в Movia"
        
        if panel.runModal() == .OK {
            addFiles(panel.urls)
        }
    }
    
    public func addFiles(_ urls: [URL]) {
        Task {
            for url in urls {
                do {
                    let item = try await VideoMetadataExtractor.extractMetadata(from: url)
                    await MainActor.run {
                        self.queue.append(item)
                        self.processedURL = nil
                        self.setActiveVideo(index: self.queue.count - 1)
                    }
                } catch {
                    print("Error importing \(url.lastPathComponent): \(error)")
                }
            }
        }
    }
    
    public func setActiveVideo(index: Int) {
        guard index >= 0, index < queue.count else { return }
        self.activeIndex = index
        let item = queue[index]
        self.trimStart = item.trimStart
        self.trimEnd = item.trimEnd > 0 ? item.trimEnd : item.duration
        self.totalDuration = item.duration
        self.currentTime = 0.0
        self.progress = 0.0
        self.processedURL = nil
        
        loadPlayerItem(url: item.url)
        setupTimeObserver()
        
        // Generate lightweight filmstrip for precision timeline
        Task {
            let frames = await FilmstripGenerator.shared.generateFilmstrip(for: item.url, count: 24)
            await MainActor.run {
                self.filmstripImages = frames
            }
        }
    }
    
    public func removeFile(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        queue.remove(at: index)
        if queue.isEmpty {
            activeIndex = -1
            player.replaceCurrentItem(with: nil)
            processedURL = nil
            totalDuration = 0.0
            currentTime = 0.0
            trimStart = 0.0
            trimEnd = 0.0
            filmstripImages = []
        } else {
            let nextIndex = min(index, queue.count - 1)
            setActiveVideo(index: nextIndex)
        }
    }
    
    public func setInAtCurrentTime() {
        self.trimStart = min(currentTime, max(0.0, trimEnd - 0.1))
        seek(to: trimStart)
    }
    
    public func setOutAtCurrentTime() {
        self.trimEnd = max(currentTime, min(totalDuration, trimStart + 0.1))
        seek(to: trimEnd)
    }
    
    public func splitAtCurrentTime() {
        if currentTime > trimStart && currentTime < trimEnd {
            // Cut at playhead: keep the selected portion up to current playhead
            self.trimEnd = currentTime
        } else if currentTime <= trimStart {
            self.trimStart = currentTime
        } else {
            self.trimEnd = min(totalDuration, currentTime)
        }
    }
    
    public func resetTrim() {
        self.trimStart = 0.0
        self.trimEnd = totalDuration
        seek(to: 0.0)
    }
    
    private func loadPlayerItem(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.audioTimePitchAlgorithm = .timeDomain
        self.player.replaceCurrentItem(with: playerItem)
        self.player.actionAtItemEnd = .pause
        self.isPlaying = false
    }
    
    public func switchPreviewMode(to mode: PreviewMode) {
        self.previewMode = mode
        guard let item = activeItem else { return }
        
        let wasPlaying = isPlaying
        player.pause()
        
        if mode == .processed, let processed = processedURL {
            // Load the actual rendered zero-flicker file
            loadPlayerItem(url: processed)
            totalDuration = item.duration * currentEffectiveSpeed
            seek(to: currentTime * currentEffectiveSpeed)
        } else {
            // Load the original item
            loadPlayerItem(url: item.url)
            totalDuration = item.duration
            seek(to: currentTime)
            if mode == .processed {
                // Live proxy rate
                player.rate = Float(1.0 / max(1.0, currentEffectiveSpeed))
            } else {
                player.rate = 1.0
            }
        }
        
        if wasPlaying {
            togglePlayPause()
        }
    }
    
    private func setupTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        let interval = CMTime(seconds: 0.04, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTime = time.seconds
                
                // Loop playback inside the trimmed range
                if self.isPlaying && self.trimEnd > self.trimStart && self.currentTime >= self.trimEnd {
                    self.seek(to: self.trimStart)
                    self.updatePlaybackRate()
                }
            }
        }
    }
    
    public func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= trimEnd && trimEnd > trimStart {
                seek(to: trimStart)
            }
            updatePlaybackRate()
            isPlaying = true
        }
    }
    
    public func updatePlaybackRate() {
        guard player.currentItem != nil else { return }
        
        // If playing processed file, normal rate 1.0
        if previewMode == .processed && processedURL != nil {
            player.rate = 1.0
        } else if previewMode == .processed || previewMode == .sideBySide {
            let speed = Float(1.0 / max(1.0, currentEffectiveSpeed))
            player.rate = speed
        } else {
            player.rate = 1.0
        }
    }
    
    public func seek(to seconds: Double) {
        let clamped = max(0.0, min(totalDuration, seconds))
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
    }
    
    public func skip(seconds: Double) {
        seek(to: currentTime + seconds)
    }
    
    // MARK: - Actions
    public func startProcessing() {
        guard let item = activeItem else { return }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(item.url.deletingPathExtension().lastPathComponent)_SlowMo_\(Int(currentEffectiveSpeed))x.\(exportFormat.fileExtension)"
        savePanel.message = "Куда сохранить обработанное видео?"
        savePanel.canCreateDirectories = true
        
        if savePanel.runModal() == .OK, let destination = savePanel.url {
            executeExport(for: item, to: destination)
        }
    }
    
    public var currentEffectiveSpeed: Double {
        speedPreset == .custom ? customSpeed : speedPreset.factor
    }
    
    private func executeExport(for item: VideoItem, to destinationURL: URL) {
        isProcessing = true
        isPaused = false
        progress = 0.0
        statusMessage = "Запуск экспорта..."
        
        var exportItem = item
        exportItem.trimStart = self.trimStart
        exportItem.trimEnd = self.trimEnd
        let segmentOnly = self.isSegmentOnlyExport
        
        Task {
            do {
                try await FrameInterpolationEngine.shared.processVideo(
                    item: exportItem,
                    speedFactor: currentEffectiveSpeed,
                    targetFps: targetFps.rawValue,
                    motionBlur: motionBlur,
                    quality: processingQuality,
                    format: exportFormat,
                    memoryLimitMB: memoryLimit.megabytes,
                    isSegmentOnly: segmentOnly,
                    outputURL: destinationURL
                ) { [weak self] currentProg, status in
                    guard let self = self else { return }
                    self.progress = currentProg
                    self.statusMessage = status
                }
                
                await MainActor.run {
                    self.isProcessing = false
                    self.statusMessage = "Успешно сохранено!"
                    self.processedURL = destinationURL
                    self.recordHistory(item: item, outputURL: destinationURL)
                    
                    // Switch to Processed preview automatically to see the result
                    self.switchPreviewMode(to: .processed)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.statusMessage = "Ошибка: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func togglePause() {
        if isPaused {
            FrameInterpolationEngine.shared.resume()
            isPaused = false
        } else {
            FrameInterpolationEngine.shared.pause()
            isPaused = true
        }
    }
    
    public func cancelProcessing() {
        FrameInterpolationEngine.shared.cancel()
        isProcessing = false
        isPaused = false
        progress = 0.0
        statusMessage = "Отменено"
    }
    
    // MARK: - History & Presets
    private func recordHistory(item: VideoItem, outputURL: URL) {
        let historyEntry = HistoryItem(
            filename: item.name,
            duration: item.duration,
            speedFactor: currentEffectiveSpeed,
            sourceFps: item.sourceFps,
            targetFps: targetFps.rawValue,
            format: exportFormat.rawValue,
            outputURLString: outputURL.path,
            trimStart: trimStart,
            trimEnd: trimEnd
        )
        history.insert(historyEntry, at: 0)
        saveHistory()
    }
    
    public func applyHistorySettings(_ item: HistoryItem) {
        self.customSpeed = item.speedFactor
        self.speedPreset = .custom
        self.targetFps = TargetFPS(rawValue: item.targetFps) ?? .fps60
        if let fmt = ExportFormat.allCases.first(where: { $0.rawValue == item.format }) {
            self.exportFormat = fmt
        }
        self.currentTab = .home
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "Movia_History")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "Movia_History"),
           let saved = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.history = saved
        }
    }
    
    private func savePresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(data, forKey: "Movia_Presets")
        }
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "Movia_Presets"),
           let saved = try? JSONDecoder().decode([SlowMoPreset].self, from: data) {
            self.customPresets = saved
        }
    }
}
