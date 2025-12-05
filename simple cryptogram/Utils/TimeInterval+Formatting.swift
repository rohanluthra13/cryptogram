//
//  TimeInterval+Formatting.swift
//  simple cryptogram
//

import Foundation

extension TimeInterval {
    /// Formats as MM:SS (e.g., "02:45")
    var formattedAsMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formats as M:SS for shorter display (e.g., "2:45")
    var formattedAsShortMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
