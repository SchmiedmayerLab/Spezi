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
            func desc(_ value: Any?) -> String? {
                switch value {
                case nil:
                    nil
                case let value as any AnyOptional:
                    desc(value.unwrappedOptional)
                case .some(let value as StudyBundle.LocalizedFileReference):
                    value.filenameIncludingLocalization
                case .some(let value as QuestionnaireIssue.Value):
                    switch value {
                    case .none:
                        nil
                    case let .some(_, value):
                        desc(value)
                    }
                case .some(let value as FHIRPrimitive<FHIRString>):
                    if let value = value.value?.string {
                        "'\(value)'"
                    } else {
                        nil
                    }
                case .some(let value as URL):
                    "'\(value.absoluteString.removingPercentEncoding ?? value.absoluteString)'"
                case .some(let value):
                    String(describing: value)
                }
            }
            
            struct Item {
                let title: String
                let value: Any
                let omitIfNil: Bool
                init(_ title: String, omitIfNil: Bool = false, value: some Any) { // swiftlint:disable:this function_default_parameter_at_end
                    self.title = title
                    self.value = value
                    self.omitIfNil = omitIfNil
                }
            }
            
            func fmtMessage(_ title: String, @ArrayBuilder<Item> items: () -> [Item]) -> String {
                let items = items().compactMap { item -> (key: String, value: String)? in
                    let desc = desc(item.value)
                    return if desc == nil && item.omitIfNil {
                        nil
                    } else {
                        (item.title, desc ?? "nil")
                    }
                }
                guard !items.isEmpty else {
                    return title
                }
                let maxItemTitleLength = items.lazy.map(\.key.count).max()! // swiftlint:disable:this force_unwrapping
                return items.reduce(into: title) { result, item in
                    result.append("\n    - \(item.key):\(String(repeating: " ", count: maxItemTitleLength - item.key.count)) \(item.value)")
                }
            }
            
            return switch self {
            case let .general(.noFilesMatchingFileRef(fileRef)):
                "No files matching file ref '\(fileRef)'"
            case let .article(.documentMetadataMissingId(fileRef)):
                "Article is missing 'id' in metadata: \(fileRef.filenameIncludingLocalization)"
            case let .article(.documentMetadataIdMismatchToBase(baseLocalization, fileRef, baseId, localizedFileRefId)):
                fmtMessage("Localized Article id does not match base localization's id") {
                    Item("base localization", value: baseLocalization)
                    Item("localized article", value: fileRef)
                    Item("base id", value: baseId)
                    Item("localized articleid", value: localizedFileRefId)
                }
            case let .questionnaire(.missingField(fileRef, path, comment)):
                fmtMessage("Questionnaire: missing field value") {
                    Item("file", value: fileRef)
                    Item("path", value: path)
                    Item("comment", omitIfNil: true, value: comment)
                }
            case let .questionnaire(.invalidField(fileRef, path, fieldValue, failureReason)):
                fmtMessage("Questionnaire: invalid field value") {
                    Item("file", value: fileRef)
                    Item("path", value: path)
                    Item("value", value: fieldValue)
                    Item("issue", value: failureReason)
                }
            case let .questionnaire(.conflictingFieldValues(fileRef, fstPath, fstValue, sndPath, sndValue, comment)):
                fmtMessage("Conflicting field values withon questionnaire") {
                    Item("questionnaire", value: fileRef)
                    Item("1st value path", value: fstPath)
                    Item("1st value", value: fstValue)
                    Item("2nd value path", value: sndPath)
                    Item("2nd value", value: sndValue)
                    Item("comment", omitIfNil: true, value: comment)
                }
            case let .questionnaire(.mismatchingFieldValues(baseFileRef, localizedFileRef, path, baseValue, localizedValue)):
                fmtMessage("Localized Questionnaire: field value does not match base localization") {
                    Item("base questionnaire", value: baseFileRef)
                    Item("localized questionnaire", value: localizedFileRef)
                    Item("path", value: path)
                    Item("base questionnaire value", value: baseValue)
                    Item("localized questionnaire value", value: localizedValue)
                }
            case let .questionnaire(.languageDiffersFromFilenameLocalization(fileRef, questionnaireLanguage)):
                fmtMessage("Questionnaire: language in metadata does not match filename localization component") {
                    Item("questionnaire", value: fileRef)
                    Item("metadata lang", value: questionnaireLanguage)
                }
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
