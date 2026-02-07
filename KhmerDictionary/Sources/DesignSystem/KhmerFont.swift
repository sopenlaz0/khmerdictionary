import SwiftUI
import UIKit

enum KhmerFont {
    private static let regularCandidates = ["Suwannaphum-Regular", "Suwannaphum"]
    private static let boldCandidates = ["Suwannaphum-Bold", "Suwannaphum"]

    static func regular(_ size: CGFloat) -> Font {
        customFont(from: regularCandidates, size: size) ?? .system(size: size)
    }

    static func bold(_ size: CGFloat) -> Font {
        customFont(from: boldCandidates, size: size) ?? .system(size: size, weight: .semibold)
    }

    static func display(_ size: CGFloat) -> Font {
        customFont(from: ["Tacteang"], size: size) ?? bold(size)
    }

    private static func customFont(from names: [String], size: CGFloat) -> Font? {
        for name in names where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }

        return nil
    }
}
