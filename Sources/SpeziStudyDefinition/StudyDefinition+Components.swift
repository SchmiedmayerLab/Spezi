//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziHealthKit
@preconcurrency import class ModelsR4.Questionnaire


// MARK: Definitions

extension StudyDefinition {
    /// A Component within a ``StudyDefinition``
    ///
    /// Study Components model schedulable and usually completable tasks or events that happen as part of a study participation.
    ///
    /// ### Component Kinds
    /// There are two kinds of components:
    /// 1. User-interactive components.
    ///     These are components which are displayed to the study participant, and typically require some kind of response.
    ///     Typically, these are used to initiate some form of data collection (e.g., prompting the user to answer a questionnaire, or to perform a six minute walking test),
    ///     but they can also be purely informational (e.g., displaying an article about some study-related topic to the user).
    /// 2. Internal, non-user-interactive components.
    ///     These are components which don't require any immediate user interaction and instead run in the background, e.g. to collect data.
    ///     An example of such a component is the background Health data collection.
    ///
    /// ### Component activation and Scheduling
    /// All study components operate on a schedule, which determines when (and how often) the component is activated.
    ///
    /// User-interactive components must have at least one explicit schedule defined in ``StudyDefinition/componentSchedules``; otherwise, they will simply be ignored and never do anything.
    /// Internal components are implicitly activated upon enrollment into the study.
    public enum Component: Identifiable, StudyDefinitionElement {
        /// Component Kind
        public enum Kind: Hashable, Sendable { // swiftlint:disable:this type_contents_order
            /// A user-interactive component
            case userInteractive
            /// An internal component
            case `internal`
        }
        /// A component that prompts the participant to read an informative article.
        case informational(InformationalComponent)
        /// A component that prompts the participant to anwer a questionnaire.
        case questionnaire(QuestionnaireComponent)
        /// A component that initiates background Health data collection.
        case healthDataCollection(HealthDataCollectionComponent)
        
        /// The components `id`, uniquely identifying it within the ``StudyDefinition``.
        public var id: UUID {
            switch self {
            case .informational(let component):
                component.id
            case .healthDataCollection(let component):
                component.id
            case .questionnaire(let component):
                component.id
            }
        }
        
        /// The Component's kind
        public var kind: Kind {
            switch self {
            case .informational, .questionnaire:
                .userInteractive
            case .healthDataCollection:
                .internal
            }
        }
    }
}


extension StudyDefinition {
    /// Study Component which prompts the participant to read an informational article
    public struct InformationalComponent: Identifiable, StudyDefinitionElement {
        public var id: UUID
        public var title: String
        public var headerImage: String
        public var body: String
        
        public init(id: UUID, title: String, headerImage: String, body: String) {
            self.id = id
            self.title = title
            self.headerImage = headerImage
            self.body = body
        }
    }
}


extension StudyDefinition {
    /// Study Component which prompts the participant to answer a questionnaire
    public struct QuestionnaireComponent: Identifiable, StudyDefinitionElement {
        /// - parameter id: the id of this study component, **not** of the questionnaire
        public let id: UUID
        public let questionnaire: Questionnaire
        
        public init(id: UUID, questionnaire: Questionnaire) {
            self.id = id
            self.questionnaire = questionnaire
        }
    }
}


extension StudyDefinition {
    /// Study Component which initiates background Health data collection
    public struct HealthDataCollectionComponent: Identifiable, StudyDefinitionElement {
        public var id: UUID
        public var sampleTypes: SampleTypesCollection
        
        public init(id: UUID, sampleTypes: SampleTypesCollection) {
            self.id = id
            self.sampleTypes = sampleTypes
        }
    }
}


// MARK: Mutating

extension StudyDefinition {
    /// Removes the component at the specified index from the study.
    ///
    /// This removes both the component itself, as well as any schedules referencing it.
    public mutating func removeComponent(at idx: Int) {
        let component = components.remove(at: idx)
        componentSchedules.removeAll { $0.componentId == component.id }
    }
}
