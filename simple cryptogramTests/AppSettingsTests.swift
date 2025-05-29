//
//  AppSettingsTests.swift
//  simple cryptogramTests
//
//  Created on 25/05/2025.
//

import XCTest
@testable import simple_cryptogram

@MainActor
final class AppSettingsTests: XCTestCase {
    
    var appSettings: AppSettings!
    var mockPersistence: MockPersistence!
    
    override func setUp() {
        super.setUp()
        mockPersistence = MockPersistence()
        appSettings = AppSettings(persistence: mockPersistence)
    }
    
    override func tearDown() {
        appSettings = nil
        mockPersistence = nil
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
        // Change settings
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]
        appSettings.textSize = .large
        
        // Verify persistence was called
        XCTAssertEqual(mockPersistence.storedValues["appSettings.encodingType"] as? String, "Numbers")
        XCTAssertEqual(mockPersistence.storedValues["appSettings.selectedDifficulties"] as? [String], ["hard"])
        XCTAssertEqual(mockPersistence.storedValues["appSettings.textSize"] as? String, "large")
    }
    
    // MARK: - Reset Tests
    
    func testResetToUserDefaults() {
        // Change settings
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]
        
        // Save as user defaults
        appSettings.saveAsUserDefaults()
        
        // Change settings again
        appSettings.encodingType = "Letters"
        appSettings.selectedDifficulties = ["easy", "medium", "hard"]
        
        // Reset to user defaults
        appSettings.reset()
        
        // Should go back to saved user defaults
        XCTAssertEqual(appSettings.encodingType, "Numbers")
        XCTAssertEqual(appSettings.selectedDifficulties, ["hard"])
    }
    
    func testResetToFactory() {
        // Change settings
        appSettings.encodingType = "Numbers"
        appSettings.selectedDifficulties = ["hard"]
        appSettings.textSize = .large
        
        // Save as user defaults
        appSettings.saveAsUserDefaults()
        
        // Reset to factory
        appSettings.resetToFactory()
        
        // Should go back to factory defaults
        XCTAssertEqual(appSettings.encodingType, "Letters")
        XCTAssertEqual(appSettings.selectedDifficulties, ["easy", "medium", "hard"])
        XCTAssertEqual(appSettings.textSize, .medium)
    }
    
    // MARK: - Migration Tests
    
    func testMigrationFromAppStorage() {
        // Set up @AppStorage values in mock persistence
        mockPersistence.storedValues["encodingType"] = "Numbers"
        mockPersistence.storedValues["autoSubmitLetter"] = true
        mockPersistence.storedValues["navBarLayout"] = "leftLayout"
        mockPersistence.storedValues["textSize"] = "large"
        mockPersistence.storedValues["hapticFeedbackEnabled"] = false
        
        // Create new AppSettings instance to trigger migration
        let migratedSettings = AppSettings(persistence: mockPersistence)
        
        // Verify migration worked
        XCTAssertEqual(migratedSettings.encodingType, "Numbers")
        XCTAssertTrue(migratedSettings.autoSubmitLetter)
        XCTAssertEqual(migratedSettings.navigationBarLayout, .leftLayout)
        XCTAssertEqual(migratedSettings.textSize, .large)
        XCTAssertFalse(migratedSettings.hapticFeedbackEnabled)
    }
}

// MARK: - Mock Persistence

class MockPersistence: PersistenceStrategy {
    var storedValues: [String: Any] = [:]
    
    func value<T>(for key: String, type: T.Type) -> T? where T: Codable {
        return storedValues[key] as? T
    }
    
    func setValue<T>(_ value: T, for key: String) where T: Codable {
        storedValues[key] = value
    }
    
    func removeValue(for key: String) {
        storedValues.removeValue(forKey: key)
    }
    
    func synchronize() {
        // No-op for mock
    }
}