import SwiftUI

public struct TopHeaderView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Traffic lights reserve
            Spacer()
                .frame(width: 60)
            
            // App Logo and Title
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "film.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Movia")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
            }
            
            Spacer()
            
            // Center Navigation Tabs (Главная, Настройки)
            HStack(spacing: 2) {
                ForEach([NavTab.home, NavTab.settings]) { tab in
                    Button(action: {
                        appState.currentTab = tab
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: appState.currentTab == tab ? .medium : .regular))
                            .foregroundColor(appState.currentTab == tab ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                                    .fill(appState.currentTab == tab ? FCPTheme.cardBackground : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: FCPTheme.radiusButton + 2)
                    .fill(FCPTheme.panelBackground)
            )
            
            Spacer()
            
            // ANE Status Pill
            HStack(spacing: 6) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FCPTheme.textPrimary)
                
                Text("ANE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FCPTheme.textPrimary)
                
                Circle()
                    .fill(appState.thermalMonitor.isThrottled ? FCPTheme.warningYellow : FCPTheme.aneGreen)
                    .frame(width: 6, height: 6)
                
                Text(appState.thermalMonitor.isThrottled ? "Охлаждение" : "Активен")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(FCPTheme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: FCPTheme.radiusPill)
                    .fill(FCPTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusPill)
                            .stroke(FCPTheme.border, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FCPTheme.panelBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(FCPTheme.border),
            alignment: .bottom
        )
    }
}
