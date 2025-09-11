//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
public import SensorKit


// MARK: On-Wrist Detection

extension SRWristDetection: SensorKitSampleProtocol {
    public typealias SafeRepresentation = SensorKitOnWristEventSample
    
    public static func processIntoSafeRepresentation(
        _ samples: some Sequence<(timestamp: Date, sample: SRWristDetection)>
    ) -> [SensorKitOnWristEventSample] {
        samples.map { .init(timestamp: $0, sample: $1) }
    }
}


/// An On-Wrist Event collected by SensorKit.
public struct SensorKitOnWristEventSample: SensorKitSampleSafeRepresentation {
    public static var sensor: Sensor<SRWristDetection> {
        .onWrist
    }
    
    public let id: UUID
    
    /// The date when this sample was collected
    public let timestamp: Date
    
    /// Whether the watch was on the user's wrist.
    public let onWrist: Bool
    public let wristLocation: SRWristDetection.WristLocation
    public let crownOrientation: SRWristDetection.CrownOrientation
    
    /// Start date of the recent on-wrist state.
    ///
    /// When the state changes from off-wrist to on-wrist, ``onWristDate`` would be updated to the current date, and ``offWristDate`` would remain the same.
    /// When the state changes from on-wrist to off-wrist, ``offWristDate`` would be updated to the current date, and ``onWristDate`` would remain the same.
    public let onWristDate: Date?
    
    /// Start date of the recent off-wrist state.
    ///
    /// When the state changes from off-wrist to on-wrist, ``onWristDate`` would be updated to the current date, and ``offWristDate`` would remain the same.
    /// When the state changes from on-wrist to off-wrist, ``offWristDate`` would be updated to the current date, and ``onWristDate`` would remain the same.
    public let offWristDate: Date?
    
    init(timestamp: Date, sample: SRWristDetection) {
        self.id = UUID() // ewwww
        self.timestamp = timestamp
        self.onWrist = sample.onWrist
        self.wristLocation = sample.wristLocation
        self.crownOrientation = sample.crownOrientation
        self.onWristDate = sample.onWristDate
        self.offWristDate = sample.offWristDate
    }
}
