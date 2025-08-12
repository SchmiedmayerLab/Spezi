//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Observation
@_documentation(visibility: internal) @_exported @preconcurrency public import SensorKit
public import Spezi


/// Interact with SensorKit in your Spezi application
///
/// ## Topics
///
/// ### Initializers
/// - ``init()``
///
/// ### Authorization Handling
/// - ``authorizationStatus(for:)``
/// - ``requestAccess(to:)``
@Observable
public final class SensorKit: Module, EnvironmentAccessible, Sendable {
    public nonisolated init() {}
}


// MARK: Authorization

extension SensorKit {
    /// Checks the  current authorization status of the specified sensor.
    public nonisolated func authorizationStatus(for sensor: Sensor<some Any>) -> SRAuthorizationStatus {
        SRSensorReader(sensor: sensor.srSensor).authorizationStatus
    }
    
    /// Requests access to read data from the specified ``Sensor``s.
    public nonisolated func requestAccess(to sensors: [any AnySensor]) async throws {
        do {
            try await SRSensorReader.requestAuthorization(sensors: sensors.mapIntoSet(\.srSensor))
        } catch {
            if (error as? SRError)?.code == .promptDeclined,
               (error as NSError).underlyingErrors.contains(where: { ($0 as NSError).code == 8201 }) {
                // the request failed bc we're already authenticated.
                return
            } else {
                throw error
            }
        }
    }
}
