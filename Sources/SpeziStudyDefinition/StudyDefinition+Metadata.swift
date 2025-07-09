//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension StudyDefinition {
    /// Study Metadata
    public struct Metadata: Identifiable, StudyDefinitionElement {
        /// The icon that should be used when displaying the study to a user.
        public enum Icon: StudyDefinitionElement {
            case systemSymbol(String)
            case custom(URL)
        }
        
        /// The study's unique identifier.
        public var id: UUID
        /// The study's user-visible title.
        ///
        /// E.g., "MyHeart Counts"
        public var title: String
        /// The study's user-visible short title
        ///
        /// E.g., "MHC"
        public var shortTitle: String
        /// Icon that will be used for this study.
        public var icon: Icon?
        /// Long-form explanation of and/or introduction to the study.
        /// Is presented to the user
        public var explanationText: String
        /// Text that is presented to the user when they eg browse a list of studies they can enroll in
        public var shortExplanationText: String
        
        /// Other studies this study depends on.
        ///
        /// A participant can only enroll in this study, if they are already enrolled in the other study referenced via this property.
        public var studyDependency: StudyDefinition.ID?
        
        /// The criteria which need to be satisfied by a person wishing to participate in the study
        public var participationCriterion: ParticipationCriterion
        
        /// The condition by which it is determined whether someone who satisfies the ``participationCriterion`` is allowed to enroll into the study.
        public var enrollmentConditions: EnrollmentConditions
        
        /// The study's consent file.
        public var consentFileRef: StudyBundle.FileReference?
        
        /// Creates a new `Metadata` object.
        public init(
            id: UUID,
            title: String,
            shortTitle: String = "",
            icon: Icon? = nil, // swiftlint:disable:this function_default_parameter_at_end
            explanationText: String,
            shortExplanationText: String,
            studyDependency: StudyDefinition.ID? = nil, // swiftlint:disable:this function_default_parameter_at_end
            participationCriterion: ParticipationCriterion,
            enrollmentConditions: EnrollmentConditions,
            consentFileRef: StudyBundle.FileReference? = nil
        ) {
            self.id = id
            self.title = title
            self.shortTitle = shortTitle
            self.icon = icon
            self.explanationText = explanationText
            self.shortExplanationText = shortExplanationText
            self.studyDependency = studyDependency
            self.participationCriterion = participationCriterion
            self.enrollmentConditions = enrollmentConditions
            self.consentFileRef = consentFileRef
        }
    }
}
