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
            
            // Bottom "О программе" Button
            VStack(spacing: 4) {
                Divider()
                    .background(FCPTheme.subtleBorder)
                    .padding(.bottom, 4)
                
                Button(action: {
                    appState.currentTab = .about
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(appState.currentTab == .about ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Text("О программе")
                            .font(.system(size: 13, weight: appState.currentTab == .about ? .medium : .regular))
                            .foregroundColor(appState.currentTab == .about ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                            .fill(appState.currentTab == .about ? FCPTheme.cardBackground : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 170)
        .background(FCPTheme.panelBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(FCPTheme.border),
            alignment: .trailing
        )
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
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? FCPTheme.textPrimary : FCPTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: FCPTheme.radiusButton)
                    .fill(isSelected ? FCPTheme.cardBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
