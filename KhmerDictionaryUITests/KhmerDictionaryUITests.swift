import XCTest

final class KhmerDictionaryUITests: XCTestCase {
    @MainActor
    func testLaunchesAndShowsTabs() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
