import Foundation
import SwiftUI
import AppKit
import AVFoundation

@MainActor
public final class AppState: ObservableObject {
    // Navigation & UI Theme
    @Published public var currentTab: NavTab = .home
    @Published public var selectedSidebarItem: SidebarItem = .project
    @Published public var uiTheme: AppUITheme = {
        if let saved = UserDefaults.standard.string(forKey: "movia_ui_theme"),
           let theme = AppUITheme(rawValue: saved) {
            return theme
        }
        return .liquidGlass
    }() {
        didSet {
            UserDefaults.standard.set(uiTheme.rawValue, forKey: "movia_ui_theme")
        }
    }
    
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
    @Published public var isMotionBlurEnabled: Bool = false
    @Published public var motionBlur: Double = 0.5 // 0.0 to 1.0 (Off to High)
    
    public var effectiveMotionBlur: Double {
        isMotionBlurEnabled ? motionBlur : 0.0
    }
    
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
    @Published public var slowmoEngine: SlowmoEngine = .fast
    @Published public var exportResolution: ExportResolution = .original
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
    
    // Storage & Export Defaults
    @Published public var useDefaultExportFolder: Bool = {
        UserDefaults.standard.bool(forKey: "movia_use_default_export_folder")
    }() {
        didSet {
            UserDefaults.standard.set(useDefaultExportFolder, forKey: "movia_use_default_export_folder")
        }
    }
    
    @Published public var defaultExportPath: String = {
        if let saved = UserDefaults.standard.string(forKey: "movia_default_export_path"), !saved.isEmpty {
            return saved
        }
        let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first?.path
        return movies ?? NSHomeDirectory()
    }() {
        didSet {
            UserDefaults.standard.set(defaultExportPath, forKey: "movia_default_export_path")
        }
    }
    
    // Cache Management
    @Published public var customCachePath: String = {
        if let saved = UserDefaults.standard.string(forKey: "movia_custom_cache_path"), !saved.isEmpty {
            return saved
        }
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Movia", isDirectory: true).path
        return caches ?? NSTemporaryDirectory()
    }() {
        didSet {
            UserDefaults.standard.set(customCachePath, forKey: "movia_custom_cache_path")
            updateCacheSize()
        }
    }
    
    @Published public var cacheSizeBytesString: String = "0 МБ"
    
    // History & Presets
    @Published public var history: [HistoryItem] = []
    @Published public var customPresets: [SlowMoPreset] = []
    
    // Thermal & Hardware monitor
    @ObservedObject public var thermalMonitor = ThermalMonitor.shared
    
    // Keyboard monitor for Global / Timeline Shortcuts
    private var keyEventMonitor: Any?
    
    public init() {
        loadHistory()
        loadPresets()
        updateCacheSize()
        setupKeyboardMonitor()
    }
    
    deinit {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupKeyboardMonitor() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // If user is currently typing in an input field (NSTextView / NSTextField), do not steal the keystroke
            if let responder = NSApp.keyWindow?.firstResponder {
                if responder is NSTextView || responder is NSTextField {
                    return event
                }
            }
            
            // Only handle shortcuts when an item is active
            guard self.activeItem != nil else { return event }
            
            let isPlain = !event.modifierFlags.contains(.command) && 
                          !event.modifierFlags.contains(.control) && 
                          !event.modifierFlags.contains(.option)
            
            if isPlain {
                let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
                
                // 1. Spacebar: Play / Pause (keyCode 49 or char " ")
                if event.keyCode == 49 || chars == " " {
                    self.togglePlayPause()
                    return nil
                }
                
                // 2. In-Point: [ (US) or 'х' (RU) (keyCode 33 is LeftBracket, or chars)
                if event.keyCode == 33 || chars == "[" || chars == "х" {
                    self.setInAtCurrentTime()
                    return nil
                }
                
                // 3. Out-Point: ] (US) or 'ъ' (RU) (keyCode 30 is RightBracket, or chars)
                if event.keyCode == 30 || chars == "]" || chars == "ъ" {
                    self.setOutAtCurrentTime()
                    return nil
                }
                
                // 4. Left Arrow: step 1 frame backward (keyCode 123)
                if event.keyCode == 123 {
                    self.stepFrame(forward: false)
                    return nil
                }
                
                // 5. Right Arrow: step 1 frame forward (keyCode 124)
                if event.keyCode == 124 {
                    self.stepFrame(forward: true)
                    return nil
                }
                
                // 6. Up Arrow: jump to In-point (keyCode 126)
                if event.keyCode == 126 {
                    self.seek(to: self.trimStart)
                    return nil
                }
                
                // 7. Down Arrow: jump to Out-point (keyCode 125)
                if event.keyCode == 125 {
                    self.seek(to: self.trimEnd)
                    return nil
                }
            }
            
            return event
        }
    }
    
    // MARK: - Export and Cache Folder Pickers
    public func selectDefaultExportFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Выберите папку для сохранения готовых видеороликов"
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.defaultExportPath = selectedURL.path
        }
    }
    
    public func selectCustomCacheFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Выберите папку для временных файлов и кэша Movia"
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.customCachePath = selectedURL.path
        }
    }
    
    public func clearCache() {
        let path = customCachePath
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(atPath: path) {
                for file in files {
                    let fullPath = (path as NSString).appendingPathComponent(file)
                    try? fm.removeItem(atPath: fullPath)
                }
            }
            // Also clean system temp files from Movia
            let tempDir = NSTemporaryDirectory()
            if let tempFiles = try? fm.contentsOfDirectory(atPath: tempDir) {
                for f in tempFiles where f.contains("movia") || f.contains("SlowMo") {
                    try? fm.removeItem(atPath: (tempDir as NSString).appendingPathComponent(f))
                }
            }
            Task { @MainActor [weak self] in
                self?.updateCacheSize()
            }
        }
    }
    
    public func updateCacheSize() {
        let path = customCachePath
        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            var totalBytes: Int64 = 0
            if let enumerator = fm.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let size = res.fileSize {
                        totalBytes += Int64(size)
                    }
                }
            }
            let mb = Double(totalBytes) / (1024.0 * 1024.0)
            let formatted: String
            if mb >= 1024.0 {
                formatted = String(format: "%.1f ГБ", mb / 1024.0)
            } else {
                formatted = String(format: "%.0f МБ", mb)
            }
            Task { @MainActor [weak self] in
                self?.cacheSizeBytesString = formatted
            }
        }
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
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .timeDomain
        self.player.replaceCurrentItem(with: playerItem)
        self.player.actionAtItemEnd = .none
        self.isPlaying = false
    }
    
    public func switchPreviewMode(to mode: PreviewMode) {
        self.previewMode = mode
        guard let item = activeItem else { return }
        
        let wasPlaying = isPlaying
        player.pause()
        
        if mode == .processed, let processed = processedURL {
            // Load the actual rendered slow motion file
            loadPlayerItem(url: processed)
            totalDuration = max(0.1, item.duration * currentEffectiveSpeed)
            seek(to: currentTime * currentEffectiveSpeed)
        } else {
            // Load the original item
            loadPlayerItem(url: item.url)
            totalDuration = item.duration
            seek(to: currentTime)
        }
        
        updatePlaybackRate()
        
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
            if (trimEnd > trimStart && currentTime >= trimEnd) || (totalDuration > 0 && currentTime >= totalDuration - 0.05) {
                seek(to: trimStart)
            }
            isPlaying = true
            updatePlaybackRate()
        }
    }
    
    public func updatePlaybackRate() {
        guard player.currentItem != nil else { return }
        
        if isPlaying {
            if previewMode == .processed && processedURL != nil {
                player.rate = 1.0
            } else if previewMode == .processed {
                let speed = Float(1.0 / max(1.0, currentEffectiveSpeed))
                player.rate = speed
            } else {
                player.rate = 1.0
            }
        } else {
            player.rate = 0.0
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
    
    public func stepFrame(forward: Bool) {
        let fps = activeItem?.sourceFps ?? 30.0
        let frameDuration = 1.0 / max(1.0, fps)
        let delta = forward ? frameDuration : -frameDuration
        seek(to: currentTime + delta)
    }
    
    // MARK: - Final Cut Pro Style Skimming (Instant Muted Scrubbing)
    @Published public var isSkimming: Bool = false
    @Published public var skimTime: Double? = nil
    private var wasMutedBeforeSkim: Bool = false
    
    public func performSkim(to seconds: Double) {
        guard activeItem != nil else { return }
        if !isSkimming {
            isSkimming = true
            wasMutedBeforeSkim = player.isMuted
            player.isMuted = true
        }
        skimTime = seconds
        let clamped = max(0.0, min(totalDuration, seconds))
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
    }
    
    public func endSkim() {
        if isSkimming {
            isSkimming = false
            skimTime = nil
            player.isMuted = wasMutedBeforeSkim
        }
    }
    
    // MARK: - Actions
    public static func uniqueDestinationURL(for destination: URL) -> URL {
        guard FileManager.default.fileExists(atPath: destination.path) else {
            return destination
        }
        let folder = destination.deletingLastPathComponent()
        let fullBase = destination.deletingPathExtension().lastPathComponent
        let ext = destination.pathExtension
        
        var rootName = fullBase
        var startIndex = 1
        
        // If filename already has a trailing number like "video 1", extract base and number
        if let match = fullBase.range(of: #"^(.*?)\s+(\d+)$"#, options: .regularExpression) {
            let matchString = String(fullBase[match])
            let parts = matchString.split(separator: " ")
            if parts.count >= 2, let lastNum = Int(parts.last!) {
                rootName = parts.dropLast().joined(separator: " ")
                startIndex = lastNum + 1
            }
        }
        
        var counter = startIndex
        var candidateURL = destination
        while FileManager.default.fileExists(atPath: candidateURL.path) {
            let newFilename = ext.isEmpty ? "\(rootName) \(counter)" : "\(rootName) \(counter).\(ext)"
            candidateURL = folder.appendingPathComponent(newFilename)
            counter += 1
        }
        return candidateURL
    }
    
    public func startProcessing() {
        guard let item = activeItem else { return }
        
        let baseFilename = "\(item.url.deletingPathExtension().lastPathComponent)_SlowMo_\(Int(currentEffectiveSpeed))x.\(exportFormat.fileExtension)"
        
        if useDefaultExportFolder && !defaultExportPath.isEmpty {
            let folderURL = URL(fileURLWithPath: defaultExportPath)
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let baseDestination = folderURL.appendingPathComponent(baseFilename)
            let uniqueDestination = AppState.uniqueDestinationURL(for: baseDestination)
            self.executeExport(for: item, to: uniqueDestination)
            return
        }
        
        let defaultFolder = item.url.deletingLastPathComponent()
        let initialCandidate = defaultFolder.appendingPathComponent(baseFilename)
        let uniqueName = AppState.uniqueDestinationURL(for: initialCandidate).lastPathComponent
        
        let savePanel = NSSavePanel()
        savePanel.directoryURL = defaultFolder
        savePanel.nameFieldStringValue = uniqueName
        savePanel.message = "Куда сохранить обработанное видео?"
        savePanel.canCreateDirectories = true
        
        DispatchQueue.main.async {
            if let keyWin = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible }) {
                savePanel.beginSheetModal(for: keyWin) { response in
                    if response == .OK, let destination = savePanel.url {
                        self.executeExport(for: item, to: destination)
                    }
                }
            } else if savePanel.runModal() == .OK, let destination = savePanel.url {
                self.executeExport(for: item, to: destination)
            }
        }
    }
    
    public var currentEffectiveSpeed: Double {
        speedPreset == .custom ? customSpeed : speedPreset.factor
    }
    
    private func executeExport(for item: VideoItem, to requestedDestinationURL: URL) {
        let destinationURL = AppState.uniqueDestinationURL(for: requestedDestinationURL)
        isProcessing = true
        isPaused = false
        progress = 0.0
        statusMessage = "Запуск экспорта..."
        
        var exportItem = item
        exportItem.trimStart = self.trimStart
        exportItem.trimEnd = self.trimEnd
        let segmentOnly = self.isSegmentOnlyExport
        let engine = self.slowmoEngine
        let resolution = self.exportResolution
        
        Task {
            do {
                try await FrameInterpolationEngine.shared.processVideo(
                    item: exportItem,
                    speedFactor: currentEffectiveSpeed,
                    targetFps: targetFps.rawValue,
                    motionBlur: effectiveMotionBlur,
                    quality: processingQuality,
                    format: exportFormat,
                    memoryLimitMB: memoryLimit.megabytes,
                    engine: engine,
                    resolution: resolution,
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
                    
                    // Enforce pause so playhead never moves by itself after export
                    self.isPlaying = false
                    self.player.pause()
                    self.player.rate = 0.0
                    
                    self.previewMode = .processed
                    self.loadPlayerItem(url: destinationURL)
                    self.totalDuration = max(0.1, item.duration * self.currentEffectiveSpeed)
                    self.seek(to: 0.0)
                    self.updatePlaybackRate()
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
