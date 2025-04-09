//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//


import Foundation
import SpeziStudyDefinition
import SwiftData


/// Tracks a user's enrollment into a study.
@Model
public final class StudyEnrollment {
    /// The primary key.
    @Attribute(.unique)
    public private(set) var id = UUID()
    
    /// The date when the participant enrolled into the study.
    ///
    /// This date is used as the reference for any relative date operations (e.g.: scheduling tasks relative to the start of someome's participation in a study).
    public private(set) var enrollmentDate: Date
    
    /// The identifier of the study.
    public private(set) var studyId: UUID
    /// The revision of the study.
    ///
    /// This property stores the current revision of the study as last seen by this object.
    public private(set) var studyRevision: UInt
    
    /// JSON-encoded version of the study.
    private var encodedStudy: Data
    
    /// The study.
    ///
    /// - Note: In some circumstances (e.g., if the `StudyDefinition` schema changes, and this enrollment has yet to be updated),
    ///     this value may initially be `nil` for a bit, until ``StudyManager/informAboutStudies(_:)`` was called.
    @Transient public private(set) lazy var study: StudyDefinition? = {
        try? JSONDecoder().decode(
            StudyDefinition.self,
            from: encodedStudy,
            configuration: .init(allowTrivialSchemaMigrations: true)
        )
    }()
    
    
    /// Creates a new `StudyEnrollment` object.
    init(enrollmentDate: Date, study: StudyDefinition) throws {
        self.enrollmentDate = enrollmentDate
        self.studyId = study.id
        self.studyRevision = study.studyRevision
        self.encodedStudy = try JSONEncoder().encode(study)
        self.study = study
    }
    
    
    /// Updates the enrollment's `StudyDefinition` to a new revision, if necessary.
    ///
    /// - Note: Attempting to update to a different study, or attempting to downgrade to an older revision, will result in the function simply not doing anything.
    func updateStudyDefinition(_ newStudy: StudyDefinition) throws {
        guard newStudy.id == studyId, newStudy.studyRevision > studyRevision else {
            return
        }
        // do this first so that, in case the encoding fails, we don't have a partially-updated enrollment object.
        let studyData = try JSONEncoder().encode(newStudy)
        studyRevision = newStudy.studyRevision
        encodedStudy = studyData
        study = newStudy
    }
}
