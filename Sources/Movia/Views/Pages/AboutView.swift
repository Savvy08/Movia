import SwiftUI
import AppKit

public struct AboutView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Program Icon
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "film.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)
            }
            
            VStack(spacing: 6) {
                Text("Версия 1.0.0")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
                
                Text("Инструмент для создания SlowMotion видео")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FCPTheme.textPrimary)
                
                Text("Легковестная программа для замедления видео")
                    .font(.system(size: 13))
                    .foregroundColor(FCPTheme.textSecondary)
                
                Text("by Savvy08")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FCPTheme.accentBlueLight)
                    .padding(.top, 6)
            }
            .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FCPTheme.windowBackground)
    }
}
