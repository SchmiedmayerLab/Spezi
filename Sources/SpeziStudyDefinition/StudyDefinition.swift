//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation
import SpeziHealthKit


/// A type that can appear in a ``StudyDefinition``.
public typealias StudyDefinitionElement = Hashable & Codable & Sendable


/// Defines a Study, as a composition of metadata, components, and a schedule.
///
/// ## Studies
/// The SpeziStudy package models a study definition as a combination of study metadata, a list of study components, and a list of schedules for these components.
/// A study is identified via its ``id``, which must be unique across all studies and is not allowed to change throughout a study's lifetime.
///
/// A study's ``Metadata-swift.struct`` bundles all non-content-related information about the study, such as e.g. its unique id, user-visible title and description, participation criteria, etc.
/// The actual "content" of the study is defined via the ``Component`` and ``ComponentSchedule`` types: a study is a set of components, each of which represents some "thing" that can happen
/// as part of a user's participation in the study.
/// Additionally, the study contains a list of component schedules, which define when each component should be activated.
///
/// Currently, there are 3 kinds of components:
/// 1. ``InformationalComponent``s, which display static informational text, e.g. an article;
/// 2. ``QuestionnaireComponent``s, which prompt the participant to answer a questionnaire;
/// 3. ``HealthDataCollectionComponent``s, which configure and enable background collection of HealthKit data.
///
/// The ``StudyDefinition`` type is explicitly designed to be used with Swift's `Codable` infrastructure: it conforms to both the `Encodable` protocol, as well as `DecodableWithConfiguration`.
/// This allows apps to easily locally persist study definitions across app launches, and to transfer them between devices, e.g., an a study app could host its study definition on a server and then
/// on each launch dynamically fetch the current version of the study from the server, thereby eliminating the need to tie the study's definition (and any changes made to it) to specific versions of the app.
///
/// Every ``Component`` within a study definition is `Identifiable` and must have a strong identity, which is not allowed to change throughout the lifetime of the study.
///
/// ## Study Evolution
/// There are two kinds of possible changes the ``StudyDefinition`` type (as well as apps/libraries using it) must be able to cope with:
/// 1. **Study Content Evolution:** changes made within a study; e.g., adding a new component, modifying an existing component, adjusting some component's schedule, etc.
/// 2. **Study Definition Evolution:** changes made not to individual studies, but to the ``StudyDefinition`` type itself; e.g., adding/renaming/removing a property, changing a type, etc.
///
/// SpeziStudy provides facilities for gracefully dealing with these kinds of changes; see <doc:StudyEvolution> for more information on this.
///
/// ## Topics
/// ### Initializers
/// - ``init(studyRevision:metadata:components:componentSchedules:)``
/// - ``init(from:configuration:)
/// ### Instance Properties
/// - ``studyRevision``
/// - ``metadata-swift.property``
/// - ``components``
/// - ``componentSchedules``
/// - ``id``
/// ### Study Metadata
/// - ``Metadata-swift.struct``
/// ### Study Components
/// - ``Component``
/// - ``InformationalComponent``
/// - ``QuestionnaireComponent``
/// - ``HealthDataCollectionComponent``
/// ### Study Schedule
/// - ``ComponentSchedule``
/// - ``ComponentSchedule/ScheduleDefinition-swift.enum``
/// ### Supporting Types
/// - ``StudyDefinitionElement``
/// - ``EnrollmentConditions``
/// - ``ParticipationCriteria``
/// ### Working with a study definition
/// - ``allCollectedHealthData``
/// - ``healthDataCollectionComponents``
/// - ``component(withId:)``
/// - ``removeComponent(at:)``
/// - ``validate()``
public struct StudyDefinition: Identifiable, Hashable, Sendable, Encodable, DecodableWithConfiguration {
    /// The ``StudyDefinition`` type's current schema version.
    public static let schemaVersion = Version(0, 4, 0)
    
    /// The revision of the study.
    ///
    /// This value should be incremented every time a new version of the study gets released.
    public var studyRevision: UInt
    /// The study's metadata.
    public var metadata: Metadata
    /// The study's components.
    public var components: [Component]
    /// The study's component schedules, defining which of the components should be activated when.
    public var componentSchedules: [ComponentSchedule]
    
    /// The study's unique identifier.
    ///
    /// - Important: This value **MUST** remain unchanged for the entire existence of a study.
    public var id: UUID { metadata.id }
    
    /// Creates a new `StudyDefinition`.
    public init(studyRevision: UInt, metadata: Metadata, components: [Component], componentSchedules: [ComponentSchedule]) {
        self.studyRevision = studyRevision
        self.metadata = metadata
        self.components = components
        self.componentSchedules = componentSchedules
    }
}


// MARK: Accessing stuff in a study, etc

extension StudyDefinition {
    /// The combined, effective HealthKit data collection of the entire study.
    public var allCollectedHealthData: SampleTypesCollection {
        healthDataCollectionComponents.reduce(into: SampleTypesCollection()) { acc, component in
            acc.insert(contentsOf: component.sampleTypes)
        }
    }
    
    /// All ``HealthDataCollectionComponent``s
    public var healthDataCollectionComponents: [HealthDataCollectionComponent] {
        components.compactMap { component in
            switch component {
            case .healthDataCollection(let component):
                component
            case .informational, .questionnaire:
                nil
            }
        }
    }
    
    /// Returns the first component with the specified id
    public func component(withId id: Component.ID) -> Component? {
        components.first { $0.id == id }
    }
}


extension StudyDefinition.Component {
    /// The components display title
    public var displayTitle: String? {
        switch self {
        case .informational(let component):
            component.title
        case .questionnaire(let component):
            component.questionnaire.title?.value?.string
        case .healthDataCollection:
            nil
        }
    }
}


extension Swift.Duration {
    /// The duration's total length, in milliseconds.
    public var totalMilliseconds: Double {
        Double(components.seconds) * 1000 + Double(components.attoseconds) * 1e-15
    }
    
    /// The duration's total length, in seconds.
    public var totalSeconds: Double {
        totalMilliseconds / 1000
    }
}
