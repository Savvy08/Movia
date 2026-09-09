import SwiftUI
import UniformTypeIdentifiers

public struct CenterDropZoneView: View {
    @ObservedObject var appState: AppState
    @State private var isTargeted: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        Group {
            if let item = appState.activeItem {
                // State 2: Active Video Player + Segment Timeline
                activePlayerWorkspace(item: item)
            } else {
                // State 1: Pure Drag-and-Drop Area (No player)
                emptyDragDropArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCPTheme.windowBackground)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - State 1: Empty Drag-and-Drop Area
    private var emptyDragDropArea: some View {
        VStack {
            Button(action: {
                appState.openFilePicker()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isTargeted ? FCPTheme.accentBlue : FCPTheme.border,
                            style: StrokeStyle(lineWidth: 1.5, dash: [8, 8])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isTargeted ? FCPTheme.cardHover : FCPTheme.cardBackground.opacity(0.35))
                        )
                    
                    VStack(spacing: 16) {
                        // Video Icon with Plus badge
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FCPTheme.textMuted.opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 72, height: 52)
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(FCPTheme.textMuted)
                            }
                            
                            Circle()
                                .fill(FCPTheme.accentBlue)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 6, y: 6)
                        }
                        .padding(.bottom, 6)
                        
                        Text("Перетащите видеофайл")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(FCPTheme.textPrimary)
                        
                        Text("или нажмите, чтобы выбрать")
                            .font(.system(size: 13))
                            .foregroundColor(FCPTheme.textSecondary)
                        
                        VStack(spacing: 4) {
                            Text("Поддерживаемые форматы:")
                                .font(.system(size: 11))
                                .foregroundColor(FCPTheme.textMuted)
                            
                            Text("MP4  ·  MOV  ·  M4V  ·  AVI  ·  и другие")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FCPTheme.textMuted)
                        }
                        .padding(.top, 14)
                    }
                    .padding(.vertical, 40)
                }
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }
    
    // MARK: - State 2: Large Central Player + Timeline
    private func activePlayerWorkspace(item: VideoItem) -> some View {
        VStack(spacing: 12) {
            // Main Big Video Player Canvas
            ZStack(alignment: .bottom) {
                ZStack(alignment: .top) {
                    // Video Surface
                    VideoPlayerCanvasView(player: appState.player)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .background(Color.black)
                    
                    // Top Bar overlay inside player
                    HStack {
                        // File tag
                        HStack(spacing: 6) {
                            Image(systemName: "film")
                                .font(.system(size: 11))
                            Text(item.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(6)
                        
                        Spacer()
                        
                        // Mode Switcher: Original | Processed | Side by Side
                        HStack(spacing: 2) {
                            ForEach(PreviewMode.allCases) { mode in
                                let isSel = appState.previewMode == mode
                                Button(action: {
                                    appState.switchPreviewMode(to: mode)
                                }) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 11, weight: isSel ? .semibold : .regular))
                                        .foregroundColor(isSel ? .white : FCPTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(isSel ? FCPTheme.accentBlue : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(7)
                    }
                    .padding(12)
                    
                    // Side-by-side split visual overlay
                    if appState.previewMode == .sideBySide {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // "До" (Before) label on left
                                HStack {
                                    Text("До (Оригинал)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(4)
                                        .padding(12)
                                        .padding(.top, 40)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "После (SlowMo %.1fx)", appState.currentEffectiveSpeed))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(FCPTheme.accentBlue.opacity(0.85))
                                        .cornerRadius(4)
                                        .padding(12)
                                        .padding(.top, 40)
                                }
                                
                                // Vertical Split Line with Draggable Handle
                                ZStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 2)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: Color.black.opacity(0.5), radius: 4)
                                        .overlay(
                                            Image(systemName: "arrow.left.and.right")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(Color.black)
                                        )
                                }
                                .offset(x: geo.size.width * appState.splitPosition - 1)
                                .gesture(
                                    DragGesture()
                                        .onChanged { val in
                                            let ratio = val.location.x / geo.size.width
                                            appState.splitPosition = max(0.05, min(0.95, ratio))
                                        }
                                )
                            }
                        }
                    }
                }
                
                // Bottom Player Controls Bar
                HStack(spacing: 14) {
                    // Skip to In-point
                    Button(action: {
                        appState.seek(to: appState.trimStart)
                    }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FCPTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    // Big Play / Pause
                    Button(action: {
                        appState.togglePlayPause()
                    }) {
                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(FCPTheme.accentBlue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Skip to Out-point
                    Button(action: {
                        appState.seek(to: appState.trimEnd)
                    }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FCPTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    // Timecode
                    Text(formatTime(appState.currentTime))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    // Interactive Scrubber
                    GeometryReader { scrubberGeo in
                        let total = max(0.1, appState.totalDuration)
                        let progressRatio = max(0.0, min(1.0, appState.currentTime / total))
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(FCPTheme.accentBlue)
                                .frame(width: scrubberGeo.size.width * CGFloat(progressRatio), height: 4)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .offset(x: scrubberGeo.size.width * CGFloat(progressRatio) - 6)
                        }
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    let ratio = max(0.0, min(1.0, val.location.x / scrubberGeo.size.width))
                                    appState.seek(to: Double(ratio) * total)
                                }
                        )
                    }
                    .frame(height: 14)
                    
                    // Total Duration
                    Text(formatTime(appState.totalDuration))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    // Quick Replace button
                    Button(action: {
                        appState.openFilePicker()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Заменить")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(FCPTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.75))
                .cornerRadius(8)
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isTargeted ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: isTargeted ? 2 : 1)
            )
            
            // Precision Timeline View (Zoom, Filmstrip, Timecodes, Cut, In/Out)
            PrecisionTimelineView(appState: appState, item: item)
        }
        .padding(16)
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.appState.addFiles([url])
                    }
                } else if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.appState.addFiles([url])
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let secs = Int(seconds)
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }
}
