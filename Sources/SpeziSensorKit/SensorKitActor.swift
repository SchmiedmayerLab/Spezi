//
// This source file is part of the SpeziSensorKit open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Dispatch
import Foundation


/// The global actor used to coordinate SensorKit operations.
///
/// Your app never needs to interact with this directly.
@globalActor
public actor SensorKitActor {
    /// The shared actor instance.
    public static let shared = SensorKitActor()
    
    /// The underlying dispatch queue that runs the actor Jobs.
    nonisolated let dispatchQueue: DispatchSerialQueue
    
    /// The underlying unowned serial executor.
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        dispatchQueue.asUnownedSerialExecutor()
    }
    
    nonisolated var isSync: Bool {
        DispatchQueue.getSpecific(key: DispatchQueueKey.key) == DispatchQueueKey.shared
    }
    
    private init() {
        let dispatchQueue = DispatchQueue(label: "edu.stanford.MHC.SensorKit", qos: .userInitiated)
        guard let serialQueue = dispatchQueue as? DispatchSerialQueue else {
            preconditionFailure("Dispatch queue \(dispatchQueue.label) was not initialized to be serial!")
        }
        serialQueue.setSpecific(key: DispatchQueueKey.key, value: DispatchQueueKey.shared)
        self.dispatchQueue = serialQueue
    }
}


extension SensorKitActor {
    private struct DispatchQueueKey: Sendable, Hashable {
        static let shared = Self()
        static let key = DispatchSpecificKey<Self>()
        private init() {}
    }
}
