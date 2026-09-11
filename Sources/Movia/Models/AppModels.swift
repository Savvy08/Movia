import Foundation
import SwiftUI
import AppKit

public enum AppUITheme: String, CaseIterable, Identifiable {
    case classic = "Классика"
    case liquidGlass = "Liquid Glass"
    
    public var id: String { rawValue }
}

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
    case custom = "user"
    
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

public enum SlowmoEngine: String, CaseIterable, Identifiable {
    case fast = "Frame Blend"
    case quality = "RIFE v4.6"
    case maximum = "FILM"
    case flavr = "FLAVR"
    case amtG = "AMT-G"
    case emaVfi = "EMA-VFI"
    
    public var id: String { rawValue }
    
    public var badge: String? {
        switch self {
        case .flavr:
            return "требует 4 кадра, вместо 2-х"
        case .emaVfi:
            return "Metal MPS"
        case .amtG:
            return "All-Pairs 4K"
        default:
            return nil
        }
    }
    
    public var infoDescription: String {
        switch self {
        case .fast:
            return "Аппаратное кадровое смешивание (Frame Blending). 100% стабильная картинка без артефактов ИИ. Идеально для видео 60-120 FPS и мгновенного экспорта."
        case .quality:
            return "Нейросеть RIFE v4.6 на Apple Neural Engine. Двунаправленный оптический поток высокой точности для людей, спорта и плавных движений."
        case .maximum:
            return "Глубокая нейросеть FILM (Google Research). Высокоточная интерполяция сложных и резких движений с устранением желейных артефактов."
        case .flavr:
            return "Нейросеть FLAVR (Flow-Agnostic Video Representation). 3D пространственно-временные свертки. Отлично справляется со сложными текстурами, водой и дымом. Требует 4 опорных кадра."
        case .amtG:
            return "Нейросеть AMT-G (All-Pairs Multi-Field Transforms). Многомасштабное сопоставление всех пар признаков. Идеально для вращений, сложных нелинейных траекторий и деформаций."
        case .emaVfi:
            return "Нейросеть EMA-VFI с аппаратной оптимизацией под Metal Performance Shaders на Apple Silicon. Раздельное извлечение векторов движения и сохранение четкости микротекстур без размытия."
        }
    }
}

public enum ExportResolution: String, CaseIterable, Identifiable {
    case original = "Оригинал"
    case res4K    = "4K UHD (3840x2160)"
    case res1080p = "1080p (1920x1080)"
    case res720p  = "720p (1280x720)"
    
    public var id: String { rawValue }
    
    public func targetSize(for sourceSize: CGSize) -> CGSize {
        switch self {
        case .original:
            return sourceSize
        case .res4K:
            return computeFit(targetW: 3840, targetH: 2160, source: sourceSize)
        case .res1080p:
            return computeFit(targetW: 1920, targetH: 1080, source: sourceSize)
        case .res720p:
            return computeFit(targetW: 1280, targetH: 720, source: sourceSize)
        }
    }
    
    private func computeFit(targetW: CGFloat, targetH: CGFloat, source: CGSize) -> CGSize {
        guard source.width > 0 && source.height > 0 else { return CGSize(width: targetW, height: targetH) }
        let aspect = source.width / source.height
        if aspect >= 1.0 {
            let w = targetW
            let h = (targetW / aspect).rounded()
            let evenW = CGFloat(Int(w) + (Int(w) % 2))
            let evenH = CGFloat(Int(h) + (Int(h) % 2))
            return CGSize(width: evenW, height: evenH)
        } else {
            let h = targetW
            let w = (targetW * aspect).rounded()
            let evenW = CGFloat(Int(w) + (Int(w) % 2))
            let evenH = CGFloat(Int(h) + (Int(h) % 2))
            return CGSize(width: evenW, height: evenH)
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
