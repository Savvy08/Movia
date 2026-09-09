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
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(FCPTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(FCPTheme.border, lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                .fill(FCPTheme.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .stroke(FCPTheme.border, lineWidth: 1)
                )
        )
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
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? FCPTheme.cardHover : FCPTheme.panelBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: isSelected ? 1.5 : 1)
                        )
                )
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
        .background(
            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                .fill(FCPTheme.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .stroke(FCPTheme.border, lineWidth: 1)
                )
        )
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
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? FCPTheme.cardHover : FCPTheme.panelBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: isSelected ? 1.5 : 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ANE Status Card
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ANE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FCPTheme.textPrimary)
                
                Text(appState.thermalMonitor.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(FCPTheme.textSecondary)
            }
            
            Spacer()
            
            Circle()
                .fill(appState.thermalMonitor.isThrottled ? FCPTheme.warningYellow : FCPTheme.aneGreen)
                .frame(width: 8, height: 8)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                .fill(FCPTheme.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .stroke(FCPTheme.border, lineWidth: 1)
                )
        )
    }
}
