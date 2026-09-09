import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Настройки Movia")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FCPTheme.textPrimary)
                
                // Memory Limit
                VStack(alignment: .leading, spacing: 10) {
                    Text("Лимит оперативной памяти (Memory Usage)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Гарантирует, что Movia не займет больше выделенного объема ОЗУ при параллельной работе с Final Cut Pro.")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(MemoryLimitOption.allCases) { opt in
                            let isSel = appState.memoryLimit == opt
                            Button(action: {
                                appState.memoryLimit = opt
                            }) {
                                Text(opt.rawValue)
                                    .font(.system(size: 12, weight: isSel ? .medium : .regular))
                                    .foregroundColor(isSel ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isSel ? FCPTheme.cardHover : FCPTheme.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(isSel ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .fill(FCPTheme.cardBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                )
                
                // Preview Quality
                VStack(alignment: .leading, spacing: 10) {
                    Text("Качество предпросмотра (Preview Proxy)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Draft (720p) использует прокси-видео для мгновенного отклика плеера на MacBook с 8 ГБ ОЗУ.")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    Picker("", selection: $appState.previewQuality) {
                        ForEach(PreviewQuality.allCases) { q in
                            Text(q.rawValue).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 380)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .fill(FCPTheme.cardBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                )
                
                // Thermal Protection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Термозащита для MacBook Air (Thermal Protection)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FCPTheme.textPrimary)
                            
                            Text("Автоматически регулирует темп просчета при нагреве чипа M1 для предотвращения троттлинга.")
                                .font(.system(size: 11))
                                .foregroundColor(FCPTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.isThermalProtectionEnabled)
                            .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .fill(FCPTheme.cardBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                )
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCPTheme.windowBackground)
    }
}

