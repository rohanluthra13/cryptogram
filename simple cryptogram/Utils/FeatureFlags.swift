//
//  FeatureFlags.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import Foundation

/// Feature flag system for gradual rollout of refactored components
enum FeatureFlag: String, CaseIterable {
    case newNavigation = "new_navigation"
    case modernSheets = "modern_sheets"
    case modernAppSettings = "modern_app_settings"
    case extractedServices = "extracted_services"
    case performanceMonitoring = "performance_monitoring"
    
    /// Check if the feature flag is enabled
    var isEnabled: Bool {
        #if DEBUG
        // In debug builds, check UserDefaults for feature flag overrides
        return UserDefaults.standard.bool(forKey: "ff_\(rawValue)")
        #else
        // In production, gradual rollout based on feature maturity
        switch self {
        case .performanceMonitoring:
            return true // Always enable performance monitoring
        case .newNavigation:
            return true // Navigation refactoring - TESTED AND WORKING
        case .modernSheets:
            return true // Sheet presentations - TESTED AND WORKING
        case .modernAppSettings:
            return false // Settings refactoring - disabled until tested
        case .extractedServices:
            return false // Service extraction - disabled until tested
        }
        #endif
    }
    
    /// Enable a feature flag in debug builds
    static func enable(_ flag: FeatureFlag) {
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "ff_\(flag.rawValue)")
        #endif
    }
    
    /// Disable a feature flag in debug builds
    static func disable(_ flag: FeatureFlag) {
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "ff_\(flag.rawValue)")
        #endif
    }
    
    /// Get all feature flags with their current state
    static var allFlags: [(FeatureFlag, Bool)] {
        return FeatureFlag.allCases.map { ($0, $0.isEnabled) }
    }
}

/// Debug helper for feature flag management
#if DEBUG
struct FeatureFlagDebugView {
    static func printAllFlags() {
        print("🚩 Feature Flags Status:")
        for (flag, isEnabled) in FeatureFlag.allFlags {
            let status = isEnabled ? "✅ ENABLED" : "❌ DISABLED"
            print("  \(flag.rawValue): \(status)")
        }
    }
    
    static func enableAll() {
        FeatureFlag.allCases.forEach { FeatureFlag.enable($0) }
        print("🚩 All feature flags enabled")
    }
    
    static func disableAll() {
        FeatureFlag.allCases.forEach { FeatureFlag.disable($0) }
        print("🚩 All feature flags disabled")
    }
}
#endif