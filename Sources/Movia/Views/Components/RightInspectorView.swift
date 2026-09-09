import SwiftUI

public struct RightInspectorView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Card 1: Slowdown controls (2x, 4x, 8x, Custom)
                SlowdownControlsCard(appState: appState)
                
                // Card 2: Target FPS (60 FPS, 120 FPS)
                TargetFpsCard(appState: appState)
                
                // Card 3: Apple Neural Engine Status
                AneCardView(appState: appState)
                
                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .frame(width: 300)
        .background(FCPTheme.panelBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(FCPTheme.border),
            alignment: .leading
        )
    }
}
