import SwiftUI

public struct RightInspectorView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 14) {
                // Card 1: Slowdown controls (2x, 4x, 8x, Custom)
                SlowdownControlsCard(appState: appState)
                
                // Card 2: Algorithm Mode (Быстрый, Качество, Максимум)
                AlgorithmSelectionCard(appState: appState)
                
                // Card 3: Target FPS (60 FPS, 120 FPS)
                TargetFpsCard(appState: appState)
                
                // Card 4: Export Settings (Resolution & Format)
                ExportSettingsCard(appState: appState)
                
                // Card 5: Apple Neural Engine Status
                AneCardView(appState: appState)
                
                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .frame(width: 300)
        .themedFloatingIsland(theme: appState.uiTheme, cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 0)
    }
}
