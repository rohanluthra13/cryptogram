//
//  PersistenceStrategy.swift
//  simple cryptogram
//
//  Created on 25/05/2025.
//

import Foundation

/// Protocol defining the interface for persisting settings
protocol PersistenceStrategy {
    /// Retrieve a value for the given key
    func value<T>(for key: String, type: T.Type) -> T? where T: Codable
    
    /// Store a value for the given key
    func setValue<T>(_ value: T, for key: String) where T: Codable
    
    /// Remove a value for the given key
    func removeValue(for key: String)
    
    /// Force synchronization of persistent storage
    func synchronize()
}

/// UserDefaults-based implementation of PersistenceStrategy
class UserDefaultsPersistence: PersistenceStrategy {
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func value<T>(for key: String, type: T.Type) -> T? where T: Codable {
        // Handle basic types that UserDefaults supports natively
        if type == String.self {
            return defaults.string(forKey: key) as? T
        } else if type == Int.self {
            let value = defaults.integer(forKey: key)
            // Check if the key exists to differentiate between 0 and nil
            return defaults.object(forKey: key) != nil ? value as? T : nil
        } else if type == Bool.self {
            // Check if the key exists to differentiate between false and nil
            return defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) as? T : nil
        } else if type == Double.self {
            let value = defaults.double(forKey: key)
            return defaults.object(forKey: key) != nil ? value as? T : nil
        } else if type == [String].self {
            return defaults.stringArray(forKey: key) as? T
        }
        
        // For complex types, use JSON encoding
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func setValue<T>(_ value: T, for key: String) where T: Codable {
        // Handle basic types that UserDefaults supports natively
        if let stringValue = value as? String {
            defaults.set(stringValue, forKey: key)
        } else if let intValue = value as? Int {
            defaults.set(intValue, forKey: key)
        } else if let boolValue = value as? Bool {
            defaults.set(boolValue, forKey: key)
        } else if let doubleValue = value as? Double {
            defaults.set(doubleValue, forKey: key)
        } else if let arrayValue = value as? [String] {
            defaults.set(arrayValue, forKey: key)
        } else {
            // For complex types, use JSON encoding
            if let data = try? JSONEncoder().encode(value) {
                defaults.set(data, forKey: key)
            }
        }
    }
    
    func removeValue(for key: String) {
        defaults.removeObject(forKey: key)
    }
    
    func synchronize() {
        // synchronize() is deprecated but we'll call it for older iOS versions
        defaults.synchronize()
    }
}