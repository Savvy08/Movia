import SwiftUI

public struct BottomControlBarView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            // Left: File Preview Info
            HStack(spacing: 12) {
                if let thumb = appState.activeItem?.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 36)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(FCPTheme.cardBackground)
                        .frame(width: 52, height: 36)
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 14))
                                .foregroundColor(FCPTheme.textMuted)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(FCPTheme.border, lineWidth: 1)
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
                            .frame(width: 24, height: 24)
                            .background(FCPTheme.cardBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FCPTheme.cardBackground)
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(LinearGradient(
                                colors: [FCPTheme.accentBlue, FCPTheme.accentBlueLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, geo.size.width * CGFloat(appState.progress)), height: 5)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 16)
                .frame(maxWidth: 340)
                
                Text(String(format: "%.0f%%", appState.progress * 100))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FCPTheme.textSecondary)
                    .frame(width: 40, alignment: .leading)
            }
            
            Spacer()
            
            // Right: Export Format Selector and Action Button
            HStack(spacing: 14) {
                // Format Menu
                Menu {
                    ForEach(ExportFormat.allCases) { fmt in
                        Button(action: {
                            appState.exportFormat = fmt
                        }) {
                            HStack {
                                Text(fmt.rawValue)
                                if appState.exportFormat == fmt {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 13))
                            .foregroundColor(FCPTheme.textSecondary)
                        
                        Text(appState.exportFormat.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FCPTheme.textPrimary)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(FCPTheme.textMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                            .fill(FCPTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                                    .stroke(FCPTheme.border, lineWidth: 1)
                            )
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                // Primary Action Button
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                            .fill(appState.isProcessing ? FCPTheme.alertRed : FCPTheme.accentBlue)
                    )
                    .shadow(color: appState.isProcessing ? FCPTheme.alertRed.opacity(0.3) : FCPTheme.accentBlue.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(FCPTheme.panelBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(FCPTheme.border),
            alignment: .top
        )
    }
}
