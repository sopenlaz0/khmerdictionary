import SwiftUI

enum AppTheme {
    static let background = dynamicColor(
        light: UIColor(red: 0.94, green: 0.96, blue: 0.99, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.10, blue: 0.13, alpha: 1)
    )

    static let cardBackground = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.82),
        dark: UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 0.90)
    )

    static let accent = dynamicColor(
        light: UIColor(red: 0.04, green: 0.29, blue: 0.55, alpha: 1),
        dark: UIColor(red: 0.39, green: 0.67, blue: 0.94, alpha: 1)
    )

    static let secondaryText = dynamicColor(
        light: UIColor(red: 0.20, green: 0.31, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.70, green: 0.77, blue: 0.88, alpha: 1)
    )

    static let primaryText = dynamicColor(
        light: UIColor(red: 0.15, green: 0.24, blue: 0.36, alpha: 1),
        dark: UIColor(red: 0.87, green: 0.90, blue: 0.96, alpha: 1)
    )

    static let heroGradientStart = dynamicColor(
        light: UIColor(red: 0.91, green: 0.95, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1)
    )

    static let cardStroke = dynamicColor(
        light: UIColor.white.withAlphaComponent(0.55),
        dark: UIColor.white.withAlphaComponent(0.14)
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
