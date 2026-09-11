import SwiftUI

public struct TopHeaderView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack {
            // Traffic lights reserve
            Spacer()
                .frame(width: 70)
            
            Spacer()
        }
        .frame(height: 24)
        .background(FCPTheme.panelBackground.opacity(0.85))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(FCPTheme.border.opacity(0.6)),
            alignment: .bottom
        )
    }
}
