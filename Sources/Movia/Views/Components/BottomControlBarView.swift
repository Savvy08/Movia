import SwiftUI

public struct BottomControlBarView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            // Left: File Preview Info (Glass Card)
            HStack(spacing: 12) {
                if let thumb = appState.activeItem?.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 52, height: 36)
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 14))
                                .foregroundColor(FCPTheme.textMuted)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.activeItem?.name ?? "Нет активного файла")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    if let item = appState.activeItem {
                        Text("\(Int(item.resolution.width)) x \(Int(item.resolution.height))  ·  \(Int(item.sourceFps)) fps  ·  \(item.fileSizeString)")
                            .font(.system(size: 11))
                            .foregroundColor(FCPTheme.textMuted)
                    } else {
                        Text("Перетащите видео в окно")
                            .font(.system(size: 11))
                            .foregroundColor(FCPTheme.textMuted)
                    }
                }
            }
            .frame(width: 250, alignment: .leading)
            
            Spacer()
            
            // Center: Progress Bar & Status
            HStack(spacing: 12) {
                if appState.isProcessing {
                    Button(action: {
                        appState.togglePause()
                    }) {
                        Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FCPTheme.textPrimary)
                            .frame(width: 26, height: 26)
                            .themedCard(theme: appState.uiTheme, cornerRadius: 13)
                    }
                    .buttonStyle(.plain)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [FCPTheme.accent(for: appState.uiTheme), FCPTheme.accent(for: appState.uiTheme).opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(appState.progress)), height: 6)
                            .shadow(color: FCPTheme.accent(for: appState.uiTheme).opacity(0.6), radius: 6)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 16)
                .frame(maxWidth: 340)
                
                Text(String(format: "%.0f%%", appState.progress * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(FCPTheme.textSecondary)
                    .frame(width: 44, alignment: .leading)
            }
            
            Spacer()
            
            // Right: Primary Action Button (Floating Glowing Glass Pill)
            HStack(spacing: 14) {
                Button(action: {
                    if appState.isProcessing {
                        appState.cancelProcessing()
                    } else {
                        appState.startProcessing()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: appState.isProcessing ? "xmark" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(appState.isProcessing ? "Отмена" : "Обработать")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme))
                            .fill(appState.isProcessing ? FCPTheme.alertRed : FCPTheme.accent(for: appState.uiTheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme))
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(
                        color: (appState.isProcessing ? FCPTheme.alertRed : FCPTheme.accent(for: appState.uiTheme)).opacity(appState.uiTheme == .liquidGlass ? 0.6 : 0.35),
                        radius: 12,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .themedFloatingIsland(theme: appState.uiTheme, cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 0)
    }
}
