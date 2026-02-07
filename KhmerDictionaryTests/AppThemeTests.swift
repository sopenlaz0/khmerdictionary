import XCTest
import UIKit
@testable import KhmerDictionary

final class AppThemeTests: XCTestCase {
    func testBackgroundAdaptsToSystemAppearance() {
        let color = UIColor(AppTheme.background)
        let light = rgba(color, style: .light)
        let dark = rgba(color, style: .dark)

        XCTAssertNotEqual(light.red, dark.red, accuracy: 0.0001)
        XCTAssertNotEqual(light.green, dark.green, accuracy: 0.0001)
        XCTAssertNotEqual(light.blue, dark.blue, accuracy: 0.0001)
        XCTAssertLessThan(luminance(dark), luminance(light))
    }

    func testCardAndSecondaryTextAdaptToSystemAppearance() {
        let cardColor = UIColor(AppTheme.cardBackground)
        let textColor = UIColor(AppTheme.secondaryText)

        let lightCard = rgba(cardColor, style: .light)
        let darkCard = rgba(cardColor, style: .dark)
        let lightText = rgba(textColor, style: .light)
        let darkText = rgba(textColor, style: .dark)

        XCTAssertNotEqual(lightCard.red, darkCard.red, accuracy: 0.0001)
        XCTAssertNotEqual(lightText.red, darkText.red, accuracy: 0.0001)
        XCTAssertGreaterThan(luminance(darkText), luminance(lightText))
    }

    private func rgba(_ color: UIColor, style: UIUserInterfaceStyle) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return (red, green, blue, alpha)
    }

    private func luminance(_ rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)) -> CGFloat {
        (0.2126 * rgba.red) + (0.7152 * rgba.green) + (0.0722 * rgba.blue)
    }
}
