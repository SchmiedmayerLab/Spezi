//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziHealthKit
import SpeziHealthKitBulkExport


extension StudyDefinition {
    /// Study Component which initiates background Health data collection
    public struct HealthDataCollectionComponent: Identifiable, StudyDefinitionElement {
        /// Defines a ``StudyDefinition/HealthDataCollectionComponent``'s collection of historical Health data.
        public enum HistoricalDataCollection: StudyDefinitionElement {
            /// The component should not collect historical data, i.e. should limit its collection only to new data added to the Health Store.
            case disabled
            /// The component should, in addition to collecting new data added to the Health Store,
            /// also collect historical data, starting at the specified start date.
            case enabled(ExportSessionStartDate)
        }
        public var id: UUID
        public var sampleTypes: SampleTypesCollection
        public var historicalDataCollection: HistoricalDataCollection
        
        public init(id: UUID, sampleTypes: SampleTypesCollection, historicalDataCollection: HistoricalDataCollection) {
            self.id = id
            self.sampleTypes = sampleTypes
            self.historicalDataCollection = historicalDataCollection
        }
    }
}
