import SwiftUI

public enum FCPTheme {
    // Classic Palette
    public static let windowBackground = Color(red: 0.07, green: 0.07, blue: 0.08)
    public static let panelBackground  = Color(red: 0.09, green: 0.10, blue: 0.11)
    public static let cardBackground   = Color(red: 0.12, green: 0.13, blue: 0.15)
    public static let cardHover        = Color(red: 0.15, green: 0.16, blue: 0.19)
    public static let border           = Color(red: 0.18, green: 0.19, blue: 0.22)
    public static let subtleBorder     = Color(red: 0.14, green: 0.15, blue: 0.17)
    
    // Liquid Glass Palette (macOS 26 Floating Glass Islands - Fast, Solid & Optimized)
    public static let liquidWindowBackground = Color(red: 0.07, green: 0.07, blue: 0.08)
    public static let liquidPanelBackground  = Color(red: 0.10, green: 0.11, blue: 0.14)
    public static let liquidCardBackground   = Color(red: 0.14, green: 0.15, blue: 0.19)
    public static let liquidCardHover        = Color(red: 0.18, green: 0.20, blue: 0.25)
    public static let liquidBorder           = Color(red: 0.24, green: 0.27, blue: 0.33)
    public static let liquidSubtleBorder     = Color(red: 0.18, green: 0.20, blue: 0.25)
    public static let liquidCyan             = Color(red: 0.0, green: 0.78, blue: 1.0)
    public static let liquidGlow             = Color(red: 0.20, green: 0.55, blue: 1.0)
    
    // Accents
    public static let accentBlue       = Color(red: 0.28, green: 0.44, blue: 0.98)
    public static let accentBlueLight  = Color(red: 0.35, green: 0.52, blue: 1.00)
    public static let aneGreen         = Color(red: 0.20, green: 0.82, blue: 0.38)
    public static let alertRed         = Color(red: 0.95, green: 0.27, blue: 0.27)
    public static let warningYellow    = Color(red: 0.98, green: 0.73, blue: 0.18)
    
    // Text
    public static let textPrimary      = Color(red: 0.95, green: 0.96, blue: 0.97)
    public static let textSecondary    = Color(red: 0.58, green: 0.61, blue: 0.68)
    public static let textMuted        = Color(red: 0.38, green: 0.40, blue: 0.46)
    
    // Corner radii
    public static let radiusCard: CGFloat   = 10.0
    public static let radiusButton: CGFloat = 8.0
    public static let radiusPill: CGFloat   = 14.0
    
    // macOS 26 Liquid Corner radii
    public static let liquidRadiusCard: CGFloat   = 14.0
    public static let liquidRadiusButton: CGFloat = 10.0
    
    // Dynamic Accessors based on active AppUITheme
    public static func windowBg(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidWindowBackground : windowBackground
    }
    
    public static func panelBg(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidPanelBackground : panelBackground
    }
    
    public static func cardBg(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidCardBackground : cardBackground
    }
    
    public static func cardHoverBg(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidCardHover : cardHover
    }
    
    public static func borderColor(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidBorder : border
    }
    
    public static func accent(for theme: AppUITheme) -> Color {
        theme == .liquidGlass ? liquidCyan : accentBlue
    }
    
    public static func cardRadius(for theme: AppUITheme) -> CGFloat {
        theme == .liquidGlass ? liquidRadiusCard : radiusCard
    }
    
    public static func buttonRadius(for theme: AppUITheme) -> CGFloat {
        theme == .liquidGlass ? liquidRadiusButton : radiusButton
    }
}

// MARK: - Dynamic Theme Floating Island (Outer floating containers only)
public struct ThemedIslandModifier: ViewModifier {
    public var theme: AppUITheme
    public var cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        if theme == .liquidGlass {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FCPTheme.liquidPanelBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FCPTheme.panelBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Dynamic Theme Panel Modifier (Zero-lag, inner cards without expensive shadow)
public struct ThemedPanelModifier: ViewModifier {
    public var theme: AppUITheme
    public var cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        if theme == .liquidGlass {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FCPTheme.liquidPanelBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FCPTheme.panelBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Dynamic Theme Card Modifier (Fast, Solid, Zero-lag 120 FPS buttons)
public struct ThemedCardModifier: ViewModifier {
    public var theme: AppUITheme
    public var cornerRadius: CGFloat
    public var isHighlighted: Bool
    
    public func body(content: Content) -> some View {
        if theme == .liquidGlass {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            isHighlighted ?
                            Color(red: 0.05, green: 0.28, blue: 0.38) :
                            FCPTheme.liquidCardBackground
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isHighlighted ?
                            FCPTheme.liquidCyan :
                            Color.white.opacity(0.10),
                            lineWidth: isHighlighted ? 1.5 : 1
                        )
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isHighlighted ? FCPTheme.cardHover : FCPTheme.cardBackground.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(isHighlighted ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: isHighlighted ? 1.5 : 1)
                        )
                )
        }
    }
}

public extension View {
    func themedFloatingIsland(theme: AppUITheme, cornerRadius: CGFloat? = nil) -> some View {
        let radius = cornerRadius ?? FCPTheme.cardRadius(for: theme)
        return modifier(ThemedIslandModifier(theme: theme, cornerRadius: radius))
    }

    func themedPanel(theme: AppUITheme, cornerRadius: CGFloat? = nil) -> some View {
        let radius = cornerRadius ?? FCPTheme.cardRadius(for: theme)
        return modifier(ThemedPanelModifier(theme: theme, cornerRadius: radius))
    }
    
    func themedCard(theme: AppUITheme, cornerRadius: CGFloat? = nil, isHighlighted: Bool = false) -> some View {
        let radius = cornerRadius ?? (theme == .liquidGlass ? 10 : 6)
        return modifier(ThemedCardModifier(theme: theme, cornerRadius: radius, isHighlighted: isHighlighted))
    }
}
