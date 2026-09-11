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
        .themedFloatingIsland(theme: appState.uiTheme, cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 0)
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
            // Main Big Video Player Canvas (Floating Glass Island)
            ZStack(alignment: .bottom) {
                ZStack(alignment: .top) {
                    // Video Surface
                    VideoPlayerCanvasView(player: appState.player)
                        .clipShape(RoundedRectangle(cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 10))
                        .background(Color.black)
                    
                    // Top Bar overlay inside player (Floating Glass Header)
                    HStack {
                        // File tag
                        HStack(spacing: 6) {
                            Image(systemName: "film")
                                .font(.system(size: 11))
                            Text(item.name)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 8)
                        
                        Spacer()
                        
                        // Mode Switcher: Original | Processed | Side by Side
                        HStack(spacing: 4) {
                            ForEach(PreviewMode.allCases) { mode in
                                let isSel = appState.previewMode == mode
                                Button(action: {
                                    appState.switchPreviewMode(to: mode)
                                }) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 11, weight: isSel ? .semibold : .regular))
                                        .foregroundColor(isSel ? .white : FCPTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .themedCard(theme: appState.uiTheme, cornerRadius: 6, isHighlighted: isSel)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(3)
                        .themedPanel(theme: appState.uiTheme, cornerRadius: 9)
                    }
                    .padding(14)
                }
                
                // Bottom Player Controls Bar (Floating Glass Capsule)
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
                    
                    // Big Play / Pause (Glass neon circle)
                    Button(action: {
                        appState.togglePlayPause()
                    }) {
                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(FCPTheme.accent(for: appState.uiTheme))
                                    .shadow(color: FCPTheme.accent(for: appState.uiTheme).opacity(0.5), radius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    .help("Воспроизведение / Пауза (Пробел)")
                    
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
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    // Interactive Scrubber
                    GeometryReader { scrubberGeo in
                        let total = max(0.1, appState.totalDuration)
                        let progressRatio = max(0.0, min(1.0, appState.currentTime / total))
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 5)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [FCPTheme.accent(for: appState.uiTheme), FCPTheme.accent(for: appState.uiTheme).opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: scrubberGeo.size.width * CGFloat(progressRatio), height: 5)
                                .shadow(color: FCPTheme.accent(for: appState.uiTheme).opacity(0.5), radius: 4)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: Color.black.opacity(0.4), radius: 3)
                                .offset(x: scrubberGeo.size.width * CGFloat(progressRatio) - 7)
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
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    // Quick Replace button
                    Button(action: {
                        appState.openFilePicker()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Заменить")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(FCPTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .themedPanel(theme: appState.uiTheme, cornerRadius: 14)
                .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 10))
            .overlay(
                RoundedRectangle(cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 10)
                    .stroke(
                        isTargeted ? FCPTheme.accent(for: appState.uiTheme) : FCPTheme.borderColor(for: appState.uiTheme),
                        lineWidth: isTargeted ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(appState.uiTheme == .liquidGlass ? 0.35 : 0.2), radius: 16, y: 8)
            
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
