import SwiftUI

public struct MainView: View {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top App Header
            TopHeaderView(appState: appState)
            
            // Middle Content: Sidebar + Center Content + Inspector
            HStack(spacing: 0) {
                // Left Sidebar
                LeftSidebarView(appState: appState)
                
                // Center Work Area
                Group {
                    switch appState.currentTab {
                    case .home:
                        if appState.selectedSidebarItem == .history {
                            HistoryView(appState: appState)
                        } else if appState.selectedSidebarItem == .myFiles {
                            MyFilesView(appState: appState)
                        } else {
                            CenterDropZoneView(appState: appState)
                        }
                    case .settings:
                        SettingsView(appState: appState)
                    case .about:
                        AboutView(appState: appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Right Inspector (Only in Home workspace when editing video)
                if appState.currentTab == .home && appState.selectedSidebarItem == .project {
                    RightInspectorView(appState: appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Action & Progress Bar
            if appState.currentTab == .home {
                BottomControlBarView(appState: appState)
            }
        }
        .frame(minWidth: 1060, minHeight: 680)
        .background(FCPTheme.windowBackground)
        .preferredColorScheme(.dark)
    }
}
