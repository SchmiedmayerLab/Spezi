//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Observation
@_documentation(visibility: internal) @_exported public import SensorKit
public import Spezi
import SpeziFoundation
import SpeziLocalStorage
import SwiftUI


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
///
/// ## Anchored Querying
/// - ``fetchAnchored(_:)``
/// - ``resetQueryAnchor(for:)``
@Observable
public final class SensorKit: Module, EnvironmentAccessible, @unchecked Sendable {
    @ObservationIgnored @Dependency(LocalStorage.self) private var localStorage
    
    private let queryAnchorKeys = LocalStorageKeysStore<QueryAnchor> { sensor in
        LocalStorageKey("edu.stanford.SpeziSensorKit.QueryAnchors.\(sensor.id)")
    }
    
    /// Creates a new instance of the `SensorKit` module.
    public nonisolated init() {}
    
    // MARK: Authorization
    
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
    
    
    // MARK: Data Exporting
    
    /// Performs an anchored fetch.
    ///
    /// The SensorKit module internally keep track of the last time an anchored fetch was performed for a specific ``Sensor``;
    /// a fetch using this function will return only those samples that have been added to SensorKit since the last fetch for the sensor.
    ///
    /// - Note: In order to fetch data from a sensor, you first need to request permission and call ``Sensor/startRecording()``
    @available(iOS 18, *)
    public func fetchAnchored<Sample>(
        _ sensor: Sensor<Sample>
    ) async throws -> some AsyncSequence<[Sample.SafeRepresentation], any Error> {
        let anchor = ManagedQueryAnchor(
            storageKey: queryAnchorKeys.key(for: sensor),
            in: localStorage
        )
        return try await sensor.fetchBatched(anchor: anchor)
    }
    
    /// Resets the query anchor for the specified sensor.
    ///
    /// This will cause subsequent calls to ``fetchAnchored(_:)`` to potentially re-fetch already-processed samples.
    public func resetQueryAnchor(for sensor: Sensor<some Any>) throws {
        try localStorage.delete(queryAnchorKeys.key(for: sensor))
    }
}
