//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ModelsR4
import SpeziFoundation
import SpeziLocalization


extension StudyBundle {
    @_spi(APISupport)
    public enum BundleValidationIssue: CustomStringConvertible, Hashable, Sendable {
        case general(GeneralIssue)
        case article(ArticleIssue)
        case questionnaire(QuestionnaireIssue)
        
        public enum GeneralIssue: Hashable, Sendable {
            /// The study bundle doesn't contain any files that would match the file reference found in the study definition.
            case noFilesMatchingFileRef(StudyBundle.FileReference)
        }
        
        public enum ArticleIssue: Hashable, Sendable {
            case documentMetadataMissingId(fileRef: LocalizedFileReference)
            case documentMetadataIdMismatchToBase(
                baseLocalization: LocalizedFileReference,
                localizedFileRef: LocalizedFileReference,
                baseId: String,
                localizedFileRefId: String
            )
        }
        
        public var description: String {
            func desc(_ value: Any?) -> String {
                switch value {
                case nil:
                    "(nil)"
                case .some(let value as QuestionnaireIssue.Value):
                    desc(value.value)
                case .some(let value as FHIRPrimitive<FHIRString>):
                    if let value = value.value?.string {
                        "'\(value)'"
                    } else {
                        "nil"
                    }
                case .some(let value as URL):
                    "'\(value.absoluteString.removingPercentEncoding ?? value.absoluteString)'"
                case .some(let value):
                    String(describing: value)
                }
            }
            return switch self {
            case let .general(.noFilesMatchingFileRef(fileRef)):
                "No files matching file ref '\(fileRef)'"
            case let .article(.documentMetadataMissingId(fileRef)):
                "Article is missing 'id' in metadata: \(fileRef.filenameIncludingLocalization)"
            case let .article(.documentMetadataIdMismatchToBase(baseLocalization, fileRef, baseId, localizedFileRefId)):
                """
                Localized Article id does not match base localization's id
                    - base localization: \(baseLocalization.filenameIncludingLocalization)
                    - localized article: \(fileRef.filenameIncludingLocalization)
                    - base id:              \(baseId)
                    - localized article id: \(localizedFileRefId)
                """
            case let .questionnaire(.missingField(fileRef, path)):
                """
                Questionnaire: missing field value
                    - file: \(fileRef.filenameIncludingLocalization)
                    - path: \(path)
                """
            case let .questionnaire(.invalidField(fileRef, path, fieldValue, failureReason)):
                """
                Questionnaire: invalid field value
                    - file: \(fileRef.filenameIncludingLocalization)
                    - path: \(path)
                    - value: \(desc(fieldValue))
                    - issue: \(failureReason)
                """
            case let .questionnaire(.conflictingFieldValues(fileRef, fstPath, fstValue, sndPath, sndValue, comment)):
                """
                Conflicting field values withon questionnaire:
                    - questionnaire:      \(fileRef.filenameIncludingLocalization)
                    - 1st value path: \(fstPath)
                    - 1st value:      \(desc(fstValue))
                    - 2nd value path: \(sndPath)
                    - 2nd value:      \(desc(sndValue))
                    - comment:        \(comment ?? "")
                """
            case let .questionnaire(.mismatchingFieldValues(baseFileRef, localizedFileRef, path, baseValue, localizedValue)):
                """
                Localized Questionnaire: field value does not match base localization
                    - base questionnaire:      \(baseFileRef.filenameIncludingLocalization)
                    - localized questionnaire: \(localizedFileRef.filenameIncludingLocalization)
                    - path: \(path)
                    - base questionnaire value:      \(desc(baseValue))
                    - localized questionnaire value: \(desc(localizedValue))
                """
            case let .questionnaire(.languageDiffersFromFilenameLocalization(fileRef, questionnaireLanguage)):
                """
                Questionnaire: language in metadata does not match filename localization component
                    - questionnaire: \(fileRef.filenameIncludingLocalization)
                    - metadata language: \(questionnaireLanguage)
                """
            }
        }
    }
    
    
    /// Validates the StudyBundle.
    ///
    /// This function performs the following checks:
    /// - for informational components:
    ///     - check that each informational component's file ref can be resolved;
    ///     - check that for each article, all localized variants have the same `id` in their metadata;
    /// - for questionnaire components:
    ///     - check that each questionnaire component's file ref can be resolved;
    ///     - check that for each questionnaire, all localized variants share the following properties:
    ///         - questionnaire id
    ///         - number of items in the questionnaire
    ///         - item identifiers
    ///         - item types
    func validate() throws -> [BundleValidationIssue] {
        var issues: [BundleValidationIssue] = []
        issues.append(contentsOf: try validateArticles())
        issues.append(contentsOf: try validateQuestionnaires().map { .questionnaire($0) })
        return issues
    }
}


// MARK: Helpers

extension LocalizedFileResource {
    init(_ other: StudyBundle.FileReference, locale: Locale = .autoupdatingCurrent) {
        self.init("\(other.category.rawValue)/\(other.filename).\(other.fileExtension)", locale: locale)
    }
}
