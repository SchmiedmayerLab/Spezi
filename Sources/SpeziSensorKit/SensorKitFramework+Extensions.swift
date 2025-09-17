//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import SensorKit


extension SRSensorReader {
    @inlinable
    convenience init(_ sensor: some AnySensor) {
        self.init(sensor: sensor.srSensor)
    }
}

@available(iOS 17.4, *)
extension SRElectrocardiogramData.Flags: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
