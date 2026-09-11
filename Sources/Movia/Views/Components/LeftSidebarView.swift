import SwiftUI

public struct LeftSidebarView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Проект")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FCPTheme.textMuted)
                .padding(.horizontal, 16)
                .padding(.top, 14)
            
            // Sidebar buttons
            VStack(spacing: 4) {
                sidebarButton(item: .project)
                sidebarButton(item: .myFiles)
                sidebarButton(item: .history)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Bottom "Настройки" and "О программе" Buttons
            VStack(spacing: 6) {
                Divider()
                    .background(appState.uiTheme == .liquidGlass ? Color.white.opacity(0.08) : FCPTheme.subtleBorder)
                    .padding(.bottom, 4)
                
                // Settings Button
                Button(action: {
                    appState.currentTab = .settings
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(appState.currentTab == .settings ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Text("Настройки")
                            .font(.system(size: 13, weight: appState.currentTab == .settings ? .semibold : .regular))
                            .foregroundColor(appState.currentTab == .settings ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: appState.currentTab == .settings)
                }
                .buttonStyle(.plain)
                
                // About Button
                Button(action: {
                    appState.currentTab = .about
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(appState.currentTab == .about ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Text("О программе")
                            .font(.system(size: 13, weight: appState.currentTab == .about ? .semibold : .regular))
                            .foregroundColor(appState.currentTab == .about ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: appState.currentTab == .about)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 175)
        .themedFloatingIsland(theme: appState.uiTheme, cornerRadius: appState.uiTheme == .liquidGlass ? 16 : 0)
    }
    
    @ViewBuilder
    private func sidebarButton(item: SidebarItem) -> some View {
        let isSelected = (appState.currentTab == .home && appState.selectedSidebarItem == item)
        
        Button(action: {
            appState.currentTab = .home
            appState.selectedSidebarItem = item
        }) {
            HStack(spacing: 10) {
                Image(systemName: item.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .themedCard(theme: appState.uiTheme, cornerRadius: FCPTheme.buttonRadius(for: appState.uiTheme), isHighlighted: isSelected)
        }
        .buttonStyle(.plain)
    }
}
