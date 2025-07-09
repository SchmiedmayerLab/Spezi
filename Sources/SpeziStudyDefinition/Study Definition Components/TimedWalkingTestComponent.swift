//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A Timed Walking Test's configuration
public struct TimedWalkingTestConfiguration: Codable, Hashable, Sendable {
    /// The kind of a Timed Walking Test
    public enum Kind: UInt8, Codable, Hashable, CaseIterable, Sendable {
        /// A test that observes the user walking
        case walking
        /// A test that observes the user running
        case running
    }
    
    /// How long the test should be conducted
    public let duration: Duration
    /// The kind of test
    public let kind: Kind
    
    /// Creates a new Timed Walking Test configuration
    public init(duration: Duration, kind: Kind) {
        self.duration = duration
        self.kind = kind
    }
}


extension StudyDefinition {
    /// Study Component which prompts the user to perform a Timed Walking Test
    public struct TimedWalkingTestComponent: Identifiable, StudyDefinitionElement {
        public var id: UUID
        public var test: TimedWalkingTestConfiguration
        
        public init(id: UUID, test: TimedWalkingTestConfiguration) {
            self.id = id
            self.test = test
        }
    }
}


extension TimedWalkingTestConfiguration {
    private static let spellOutNumberFormatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .spellOut
        return fmt
    }()
    private static let fractionalNumberFormatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 1
        return fmt
    }()
    
    /// A textual description of the Timed Walking Test
    public var displayTitle: LocalizedStringResource {
        let durationInMin = duration.totalSeconds / 60
        let durationText: String
        if durationInMin.rounded() == durationInMin, durationInMin <= 10 { // whole number of minutes
            durationText = Self.spellOutNumberFormatter.string(from: NSNumber(value: Int(durationInMin))) ?? "\(Int(durationInMin))"
        } else {
            durationText = Self.fractionalNumberFormatter.string(from: NSNumber(value: durationInMin)) ?? String(format: "%.1f", durationInMin)
        }
        switch kind {
        case .walking:
            return "\(durationText.localizedCapitalized)-Minute Walking Test"
        case .running:
            return "\(durationText.localizedCapitalized)-Minute Running Test"
        }
    }
}
