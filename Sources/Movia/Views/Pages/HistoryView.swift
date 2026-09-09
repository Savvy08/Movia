import SwiftUI

public struct HistoryView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("История обработки")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(FCPTheme.textPrimary)
            
            if appState.history.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(FCPTheme.textMuted)
                    Text("История пуста")
                        .font(.system(size: 14))
                        .foregroundColor(FCPTheme.textSecondary)
                    Text("Здесь будут отображаться ваши обработанные видеоролики с возможностью повторить настройки.")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(appState.history) { item in
                    HStack(spacing: 14) {
                        Image(systemName: "film")
                            .font(.system(size: 18))
                            .foregroundColor(FCPTheme.accentBlue)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.filename)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FCPTheme.textPrimary)
                            
                            Text(String(format: "%.1fx  ·  %.0f→%d FPS  ·  %@", item.speedFactor, item.sourceFps, item.targetFps, item.format))
                                .font(.system(size: 11))
                                .foregroundColor(FCPTheme.textMuted)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            appState.applyHistorySettings(item)
                        }) {
                            Text("Повторить настройки")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FCPTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(FCPTheme.cardBackground)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(FCPTheme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(FCPTheme.cardBackground.opacity(0.3))
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCPTheme.windowBackground)
    }
}
