import SwiftUI

public struct MainView: View {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Unified clean solid window background for maximum performance & consistency
            FCPTheme.windowBackground
                .ignoresSafeArea()
            
            VStack(spacing: appState.uiTheme == .liquidGlass ? 10 : 0) {
                // Middle Content: Sidebar + Center Content + Inspector
                HStack(spacing: appState.uiTheme == .liquidGlass ? 10 : 0) {
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
            .padding(appState.uiTheme == .liquidGlass ? 10 : 0)
        }
        .frame(minWidth: 1180, minHeight: 750)
        .preferredColorScheme(.dark)
    }
}
