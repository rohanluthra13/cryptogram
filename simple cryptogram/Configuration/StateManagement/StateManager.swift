//
//  StateManager.swift
//  simple cryptogram
//
//  Created on 25/05/2025.
//

import Foundation
import Combine

/// Protocol defining the interface for state management components
protocol StateManager {
    associatedtype StateType
    
    /// Current state value
    var currentValue: StateType { get }
    
    /// Publisher for state changes
    var publisher: AnyPublisher<StateType, Never> { get }
    
    /// Update state value
    func update(_ newValue: StateType)
    
    /// Reset to user-defined defaults
    func reset()
    
    /// Reset to factory defaults
    func resetToFactory()
}