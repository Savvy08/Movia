import SwiftUI

public struct MyFilesView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Мои файлы")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Список добавленных видеофайлов в текущем проекте (\(appState.queue.count))")
                        .font(.system(size: 12))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    appState.openFilePicker()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Добавить файл")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                            .fill(FCPTheme.accentBlue)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(FCPTheme.panelBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(FCPTheme.border),
                alignment: .bottom
            )
            
            // Content
            if appState.queue.isEmpty {
                emptyQueueState
            } else {
                filesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCPTheme.windowBackground)
    }
    
    private var emptyQueueState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(FCPTheme.border, style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(FCPTheme.cardBackground.opacity(0.4))
                    )
                    .frame(width: 380, height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(FCPTheme.textMuted)
                    
                    Text("Нет добавленных файлов")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Button(action: {
                        appState.openFilePicker()
                    }) {
                        Text("Выбрать видеофайлы")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                                    .fill(FCPTheme.accentBlue)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
    }
    
    private var filesList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 10) {
                ForEach(appState.queue.indices, id: \.self) { idx in
                    let item = appState.queue[idx]
                    let isActive = (idx == appState.activeIndex)
                    
                    HStack(spacing: 14) {
                        // Thumbnail
                        ZStack {
                            if let thumb = item.thumbnail {
                                Image(nsImage: thumb)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 50)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        Image(systemName: "film")
                                            .font(.system(size: 16))
                                            .foregroundColor(FCPTheme.textMuted)
                                    )
                            }
                        }
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isActive ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: isActive ? 2 : 1)
                        )
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(FCPTheme.textPrimary)
                                
                                if isActive {
                                    Text("Активен в редакторе")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(FCPTheme.accentBlueLight)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(FCPTheme.accentBlue.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Text(formatDuration(item.duration))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(FCPTheme.textSecondary)
                                
                                Text("\(Int(item.resolution.width)) x \(Int(item.resolution.height))")
                                    .font(.system(size: 11))
                                    .foregroundColor(FCPTheme.textMuted)
                                
                                Text("\(Int(item.sourceFps)) fps")
                                    .font(.system(size: 11))
                                    .foregroundColor(FCPTheme.textMuted)
                                
                                Text(item.fileSizeString)
                                    .font(.system(size: 11))
                                    .foregroundColor(FCPTheme.textMuted)
                            }
                        }
                        
                        Spacer()
                        
                        // Actions
                        HStack(spacing: 8) {
                            Button(action: {
                                appState.setActiveVideo(index: idx)
                                appState.selectedSidebarItem = .project
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 11))
                                    Text(isActive ? "В редактор" : "Открыть")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(isActive ? .white : FCPTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isActive ? FCPTheme.accentBlue : FCPTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(FCPTheme.border, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                appState.removeFile(at: idx)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(FCPTheme.textMuted)
                                    .padding(7)
                                    .background(FCPTheme.cardBackground)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(FCPTheme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Удалить из списка")
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                            .fill(isActive ? FCPTheme.cardBackground : FCPTheme.panelBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                                    .stroke(isActive ? FCPTheme.accentBlue.opacity(0.6) : FCPTheme.border, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let s = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1.0)) * 1000)
        return String(format: "%02d:%02d.%03d", mins, s, ms)
    }
}
