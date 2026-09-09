import Foundation
import SwiftUI
import AppKit

public enum NavTab: String, CaseIterable, Identifiable {
    case home = "Главная"
    case settings = "Настройки"
    case about = "О программе"
    
    public var id: String { rawValue }
}

public enum SidebarItem: String, CaseIterable, Identifiable {
    case project = "Проект"
    case myFiles = "Мои файлы"
    case history = "История"
    case settings = "Настройки"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .project:    return "film"
        case .myFiles:    return "folder"
        case .history:    return "clock"
        case .settings:   return "gearshape"
        }
    }
}

public enum SlowdownPreset: String, CaseIterable, Identifiable {
    case x2 = "2x"
    case x4 = "4x"
    case x8 = "8x"
    case custom = "Кастомный"
    
    public var id: String { rawValue }
    
    public var factor: Double {
        switch self {
        case .x2: return 2.0
        case .x4: return 4.0
        case .x8: return 8.0
        case .custom: return 4.0
        }
    }
}

public enum TargetFPS: Int, CaseIterable, Identifiable {
    case fps60 = 60
    case fps120 = 120
    
    public var id: Int { rawValue }
    public var label: String { "\(rawValue) FPS" }
}

public enum PreviewMode: String, CaseIterable, Identifiable {
    case original = "Оригинал"
    case processed = "Замедленное"
    case sideBySide = "До / После"
    
    public var id: String { rawValue }
}

public enum PreviewQuality: String, CaseIterable, Identifiable {
    case draft720p = "Draft (720p)"
    case standard1080p = "Standard (1080p)"
    case original = "Original"
    
    public var id: String { rawValue }
}

public enum MemoryLimitOption: String, CaseIterable, Identifiable {
    case mb150 = "150 MB"
    case mb300 = "300 MB"
    case mb500 = "500 MB"
    case auto = "Automatic"
    
    public var id: String { rawValue }
    
    public var megabytes: Int {
        switch self {
        case .mb150: return 150
        case .mb300: return 300
        case .mb500: return 500
        case .auto:  return 300
        }
    }
}

public enum ProcessingQuality: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case balanced = "Balanced"
    case high = "High"
    case maximum = "Maximum"
    
    public var id: String { rawValue }
}

public enum ExportFormat: String, CaseIterable, Identifiable {
    case proRes422HQ = "ProRes 422 HQ"
    case proRes422   = "ProRes 422"
    case hevc        = "H.265 (HEVC)"
    case h264        = "H.264 (MP4)"
    
    public var id: String { rawValue }
    
    public var fileExtension: String {
        switch self {
        case .proRes422HQ, .proRes422: return "mov"
        case .hevc, .h264:             return "mp4"
        }
    }
}

public enum QuickExportProfile: String, CaseIterable, Identifiable {
    case bestQuality = "Best Quality (ProRes 422 HQ)"
    case balanced    = "Balanced (HEVC 60 FPS)"
    case smallFile   = "Small File (H.264 60 FPS)"
    
    public var id: String { rawValue }
}

public struct VideoItem: Identifiable, Hashable {
    public let id: UUID
    public let url: URL
    public var name: String
    public var duration: Double // seconds
    public var resolution: CGSize
    public var sourceFps: Double
    public var fileSizeString: String
    public var thumbnail: NSImage?
    
    // Segment Trim Points (0.0 to duration)
    public var trimStart: Double
    public var trimEnd: Double
    
    public var statusText: String
    public var progress: Double
    
    public init(url: URL, name: String? = nil, duration: Double = 0, resolution: CGSize = .zero, sourceFps: Double = 30, fileSizeString: String = "", thumbnail: NSImage? = nil) {
        self.id = UUID()
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.duration = duration
        self.resolution = resolution
        self.sourceFps = sourceFps
        self.fileSizeString = fileSizeString
        self.thumbnail = thumbnail
        self.trimStart = 0.0
        self.trimEnd = duration > 0 ? duration : 1.0
        self.statusText = "Waiting"
        self.progress = 0.0
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.id == rhs.id
    }
}

public struct HistoryItem: Identifiable, Codable {
    public let id: UUID
    public let filename: String
    public let date: Date
    public let duration: Double
    public let speedFactor: Double
    public let sourceFps: Double
    public let targetFps: Int
    public let format: String
    public let outputURLString: String
    public let trimStart: Double
    public let trimEnd: Double
    
    public init(filename: String, duration: Double, speedFactor: Double, sourceFps: Double, targetFps: Int, format: String, outputURLString: String, trimStart: Double, trimEnd: Double) {
        self.id = UUID()
        self.filename = filename
        self.date = Date()
        self.duration = duration
        self.speedFactor = speedFactor
        self.sourceFps = sourceFps
        self.targetFps = targetFps
        self.format = format
        self.outputURLString = outputURLString
        self.trimStart = trimStart
        self.trimEnd = trimEnd
    }
}

public struct SlowMoPreset: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var speedFactor: Double
    public var targetFps: Int
    public var motionBlur: Double
    public var quality: String
    public var format: String
    
    public init(name: String, speedFactor: Double, targetFps: Int, motionBlur: Double, quality: String, format: String) {
        self.id = UUID()
        self.name = name
        self.speedFactor = speedFactor
        self.targetFps = targetFps
        self.motionBlur = motionBlur
        self.quality = quality
        self.format = format
    }
}
