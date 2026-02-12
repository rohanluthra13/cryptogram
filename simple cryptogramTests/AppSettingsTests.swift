import XCTest
@testable import simple_cryptogram

@MainActor
final class AppSettingsTests: XCTestCase {

    var appSettings: AppSettings!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "AppSettingsTests")!
        // Clear any leftover state
        testDefaults.removePersistentDomain(forName: "AppSettingsTests")
        appSettings = AppSettings(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "AppSettingsTests")
        appSettings = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialValues() {
        XCTAssertEqual(appSettings.encodingType, "Letters")
        XCTAssertEqual(appSettings.selectedDifficulties, ["easy", "medium", "hard"])
        XCTAssertFalse(appSettings.autoSubmitLetter)
        XCTAssertEqual(appSettings.navigationBarLayout, .centerLayout)
        XCTAssertEqual(appSettings.textSize, .medium)
        XCTAssertTrue(appSettings.soundFeedbackEnabled)
        XCTAssertTrue(appSettings.hapticFeedbackEnabled)
    }

    // MARK: - Persistence Tests

    func testSettingsPersistence() {
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]
        appSettings.textSize = .large

        XCTAssertEqual(testDefaults.string(forKey: "appSettings.encodingType"), "Numbers")
        XCTAssertEqual(testDefaults.stringArray(forKey: "appSettings.selectedDifficulties"), ["hard"])
        XCTAssertEqual(testDefaults.string(forKey: "appSettings.textSize"), "large")
    }

    // MARK: - Reset Tests

    func testResetToUserDefaults() {
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]

        appSettings.saveAsUserDefaults()

        appSettings.encodingType = "Letters"
        appSettings.selectedDifficulties = ["easy", "medium", "hard"]

        appSettings.reset()

        XCTAssertEqual(appSettings.encodingType, "Numbers")
        XCTAssertEqual(appSettings.selectedDifficulties, ["hard"])
    }

    func testResetToFactory() {
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]
        appSettings.textSize = .large

        appSettings.saveAsUserDefaults()

        appSettings.resetToFactory()

        XCTAssertEqual(appSettings.encodingType, "Letters")
        XCTAssertEqual(appSettings.selectedDifficulties, ["easy", "medium", "hard"])
        XCTAssertEqual(appSettings.textSize, .medium)
    }

    // MARK: - Quote Length Display Tests (absorbed from SettingsViewModel)

    func testQuoteLengthDisplayText() {
        appSettings.selectedDifficulties = ["easy", "medium", "hard"]
        XCTAssertEqual(appSettings.quoteLengthDisplayText, "all")

        appSettings.selectedDifficulties = ["easy"]
        XCTAssertEqual(appSettings.quoteLengthDisplayText, "short")

        appSettings.selectedDifficulties = ["medium"]
        XCTAssertEqual(appSettings.quoteLengthDisplayText, "medium")

        appSettings.selectedDifficulties = ["hard"]
        XCTAssertEqual(appSettings.quoteLengthDisplayText, "long")
    }

    func testToggleLength() {
        appSettings.selectedDifficulties = ["easy", "medium", "hard"]

        appSettings.toggleLength("hard")
        XCTAssertEqual(appSettings.selectedDifficulties, ["easy", "medium"])

        // Can't deselect when only one left
        appSettings.toggleLength("easy")
        XCTAssertEqual(appSettings.selectedDifficulties, ["medium"])
        appSettings.toggleLength("medium")
        XCTAssertEqual(appSettings.selectedDifficulties, ["medium"]) // unchanged

        // Can add back
        appSettings.toggleLength("hard")
        XCTAssertTrue(appSettings.selectedDifficulties.contains("hard"))
    }
}
