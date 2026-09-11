import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Настройки Movia")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FCPTheme.textPrimary)
                
                // Appearance / UI Style
                VStack(alignment: .leading, spacing: 10) {
                    Text("Внешний вид интерфейса")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Выберите визуальный стиль интерфейса программы. Изменение сохраняется автоматически.")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    HStack(spacing: 10) {
                        ForEach(AppUITheme.allCases) { theme in
                            let isSel = appState.uiTheme == theme
                            Button(action: {
                                appState.uiTheme = theme
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: theme == .liquidGlass ? "sparkles" : "macwindow")
                                        .font(.system(size: 12))
                                    Text(theme.rawValue)
                                        .font(.system(size: 12, weight: isSel ? .semibold : .regular))
                                    if isSel {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .foregroundColor(isSel ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
                
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
                                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
                
                // Preview Quality
                VStack(alignment: .leading, spacing: 10) {
                    Text("Качество предпросмотра (Preview Proxy)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Draft (720p) использует легковесный прокси для мгновенного отклика плеера на MacBook.")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(PreviewQuality.allCases) { opt in
                            let isSel = appState.previewQuality == opt
                            Button(action: {
                                appState.previewQuality = opt
                            }) {
                                Text(opt.rawValue)
                                    .font(.system(size: 12, weight: isSel ? .medium : .regular))
                                    .foregroundColor(isSel ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
                
                // Default Export Directory
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Сохранять по умолчанию")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FCPTheme.textPrimary)
                            
                            Text("Автоматически сохранять готовое видео в выбранную папку без диалогового окна.")
                                .font(.system(size: 11))
                                .foregroundColor(FCPTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.useDefaultExportFolder)
                            .toggleStyle(.switch)
                    }
                    
                    if appState.useDefaultExportFolder {
                        HStack(spacing: 10) {
                            Text(appState.defaultExportPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(FCPTheme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                            
                            Button(action: {
                                appState.selectDefaultExportFolder()
                            }) {
                                Text("Выбрать папку...")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(FCPTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
                
                // Cache Directory & Cleanup
                VStack(alignment: .leading, spacing: 10) {
                    Text("Путь к кэшу и временным файлам")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                    
                    Text("Каталог для временных промежуточных кадров и предпросмотра. Текущий размер кэша: \(appState.cacheSizeBytesString)")
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                    
                    HStack(spacing: 10) {
                        Text(appState.customCachePath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(FCPTheme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                        
                        Button(action: {
                            appState.selectCustomCacheFolder()
                        }) {
                            Text("Путь к кэшу")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FCPTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            appState.clearCache()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                Text("Очистить кэш")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(FCPTheme.alertRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
                
                // Thermal Protection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Термальная защита (Thermal Throttling Protection)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FCPTheme.textPrimary)
                            
                            Text("Автоматически снижать приоритет вычислений ANE при нагреве чипа выше 85°C.")
                                .font(.system(size: 11))
                                .foregroundColor(FCPTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.isThermalProtectionEnabled)
                            .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .themedPanel(theme: appState.uiTheme)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedFloatingIsland(theme: appState.uiTheme, cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 0)
    }
}

