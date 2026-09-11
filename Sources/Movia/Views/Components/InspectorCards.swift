import SwiftUI

// MARK: - Slowdown Controls Card
public struct SlowdownControlsCard: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 13))
                    .foregroundColor(FCPTheme.accentBlue)
                
                Text("Замедление")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            // Preset buttons in a row
            HStack(spacing: 6) {
                presetButton(preset: .x2)
                presetButton(preset: .x4)
                presetButton(preset: .x8)
                presetButton(preset: .custom)
            }
            
            // Slider
            VStack(spacing: 6) {
                HStack {
                    Text("1.5x")
                        .font(.system(size: 10))
                        .foregroundColor(FCPTheme.textMuted)
                    
                    Slider(value: $appState.customSpeed, in: 1.5...16.0, step: 0.5)
                        .accentColor(FCPTheme.accentBlue)
                        .onChange(of: appState.customSpeed) { _, _ in
                            appState.speedPreset = .custom
                        }
                    
                    Text("16x")
                        .font(.system(size: 10))
                        .foregroundColor(FCPTheme.textMuted)
                    
                    Text(String(format: "%.1fx", appState.currentEffectiveSpeed))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .themedPanel(theme: appState.uiTheme)
    }
    
    @ViewBuilder
    private func presetButton(preset: SlowdownPreset) -> some View {
        let isSelected = (appState.speedPreset == preset)
        
        Button(action: {
            appState.speedPreset = preset
            if preset != .custom {
                appState.customSpeed = preset.factor
            }
        }) {
            Text(preset.rawValue)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Target FPS Card
public struct TargetFpsCard: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.inset.filled.and.cursorarrow")
                    .font(.system(size: 13))
                    .foregroundColor(FCPTheme.accentBlue)
                
                Text("Целевой FPS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            HStack(spacing: 8) {
                fpsButton(fps: .fps60)
                fpsButton(fps: .fps120)
            }
        }
        .padding(14)
        .themedPanel(theme: appState.uiTheme)
    }
    
    @ViewBuilder
    private func fpsButton(fps: TargetFPS) -> some View {
        let isSelected = (appState.targetFps == fps)
        
        Button(action: {
            appState.targetFps = fps
        }) {
            Text(fps.label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Algorithm Selection Card
public struct AlgorithmSelectionCard: View {
    @ObservedObject var appState: AppState
    @State private var showingInfoEngine: SlowmoEngine? = nil
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 13))
                    .foregroundColor(FCPTheme.accent(for: appState.uiTheme))
                
                Text("Алгоритм замедления")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            VStack(spacing: 8) {
                ForEach(SlowmoEngine.allCases) { engine in
                    engineRow(engine: engine)
                }
            }
        }
        .padding(14)
        .themedPanel(theme: appState.uiTheme)
    }
    
    @ViewBuilder
    private func engineRow(engine: SlowmoEngine) -> some View {
        let isSelected = (appState.slowmoEngine == engine)
        
        HStack(spacing: 8) {
            Button(action: {
                appState.slowmoEngine = engine
            }) {
                HStack(spacing: 6) {
                    Text(engine.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                    
                    if let badge = engine.badge {
                        let badgeColor: Color = {
                            switch engine {
                            case .flavr: return Color.orange
                            case .emaVfi: return Color.cyan
                            case .amtG: return Color(red: 0.65, green: 0.45, blue: 1.0)
                            default: return Color.orange
                            }
                        }()
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(badgeColor.opacity(0.18))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FCPTheme.accent(for: appState.uiTheme))
                    }
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSelected)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                if showingInfoEngine == engine {
                    showingInfoEngine = nil
                } else {
                    showingInfoEngine = engine
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(showingInfoEngine == engine ? FCPTheme.accent(for: appState.uiTheme) : FCPTheme.textMuted)
                    .frame(width: 30, height: 32)
                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: showingInfoEngine == engine)
            }
            .buttonStyle(.plain)
            .popover(isPresented: Binding(
                get: { showingInfoEngine == engine },
                set: { if !$0 { showingInfoEngine = nil } }
            ), arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(engine.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FCPTheme.textPrimary)
                        Spacer()
                    }
                    Text(engine.infoDescription)
                        .font(.system(size: 11))
                        .foregroundColor(FCPTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(width: 260)
                .background(FCPTheme.panelBackground)
            }
        }
    }
}

// MARK: - Export Settings Card (Resolution & Format)
public struct ExportSettingsCard: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 13))
                    .foregroundColor(FCPTheme.accentBlue)
                
                Text("Настройки экспорта")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            // Resolution Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Разрешение:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FCPTheme.textSecondary)
                
                Menu {
                    ForEach(ExportResolution.allCases) { res in
                        Button(action: {
                            appState.exportResolution = res
                        }) {
                            HStack {
                                Text(res.rawValue)
                                if appState.exportResolution == res {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(appState.exportResolution.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FCPTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(FCPTheme.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme))
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)
            }
            
            // Format Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Формат кодека:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FCPTheme.textSecondary)
                
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
                    HStack {
                        Text(appState.exportFormat.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FCPTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(FCPTheme.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme))
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .themedPanel(theme: appState.uiTheme)
    }
}

// MARK: - ANE & Active Model Card
public struct AneCardView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "apple.logo")
                .font(.system(size: 16))
                .foregroundColor(FCPTheme.textPrimary)
            
            HStack(spacing: 6) {
                Text("ANE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FCPTheme.textMuted)
                
                Text("·")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FCPTheme.textMuted)
                
                Text(appState.slowmoEngine.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            Spacer()
            
            Circle()
                .fill(appState.thermalMonitor.isThrottled ? FCPTheme.warningYellow : FCPTheme.aneGreen)
                .frame(width: 8, height: 8)
                .shadow(color: appState.thermalMonitor.isThrottled ? FCPTheme.warningYellow.opacity(0.6) : FCPTheme.aneGreen.opacity(0.6), radius: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .themedPanel(theme: appState.uiTheme)
    }
}
