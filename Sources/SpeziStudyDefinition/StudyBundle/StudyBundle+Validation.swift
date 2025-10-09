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
        
        public enum QuestionnaireIssue: Hashable, Sendable {
            /// The questionnaire as a whole, or one of its items, it missing a field.
            ///
            /// - parameter fileRef: The questionnaire in question.
            /// - parameter itemIdx: The index of the item this issue relates to. `nil` if a questionnaire-level field is missing.
            /// - parameter fieldName: The name of the missing field.
            case missingField(fileRef: LocalizedFileReference, itemIdx: Int?, fieldName: String)
            
            /// The questionnaire as a whole, or one of its items, contains a field with an invalid value.
            ///
            /// - parameter fileRef: The questionnaire in question.
            /// - parameter itemIdx: The index of the item this issue relates to. `nil` if a questionnaire-level field is invalid.
            /// - parameter fieldName: The name of the field im question.
            /// - parameter fieldValue: The value of the field in question.
            /// - parameter failureReason: An explanation of why exactly this field's value is invalid.
            case invalidField( // swiftlint:disable:this enum_case_associated_values_count
                fileRef: LocalizedFileReference,
                itemIdx: Int?,
                fieldName: String,
                fieldValue: Value?,
                failureReason: String
            )
            
            /// A field in a localized version of a questionnaire has a value that doesn't match the base localization.
            ///
            /// - parameter baseFileRef: The base localization of the questionnaire.
            ///     This is the version we use as the "ground truth", i.e., the version all other localizations' should match. Typically the `en-US` localization.
            /// - parameter localizedFileRef: The localization this issue relates to.
            /// - parameter itemIdx: The index of the item this issue relates to. `nil` if a questionnaire-level field is incorrect.
            /// - parameter fieldName: The name of the missing field.
            /// - parameter baseValue: The value of the field as present in the base localization. This is the "expected" value that should also be present in the `localizedFileRef`.
            /// - parameter localizedValue: The actual value of the field in the `localizedFileRef`.
            case mismatchingFieldValues( // swiftlint:disable:this enum_case_associated_values_count
                baseFileRef: LocalizedFileReference,
                localizedFileRef: LocalizedFileReference,
                itemIdx: Int?,
                fieldName: String,
                baseValue: Value?,
                localizedValue: Value?
            )
            /// The language in the questionnaire's metadata does not match the language in the filename's localization component.
            case languageDiffersFromFilenameLocalization(
                fileRef: LocalizedFileReference,
                questionnaireLanguage: String
            )
            
            public struct Value: Hashable, Sendable { // swiftlint:disable:this nesting
                private let type: Any.Type
                let value: any Hashable & Sendable
                
                init?(_ value: (some Hashable & Sendable)?) {
                    if let value {
                        self.type = Swift.type(of: value)
                        self.value = value
                    } else {
                        return nil
                    }
                }
                public static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.value.isEqual(rhs.value) && lhs.type == rhs.type
                }
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type))
                    value.hash(into: &hasher)
                }
            }
        }
        
        public var description: String {
            func desc(_ value: Any?) -> String {
                switch value {
                case nil:
                    "(nil)"
                case .some(let value as QuestionnaireIssue.Value):
                    desc(value.value)
                case .some(let value as FHIRPrimitive<FHIRString>):
                    value.value?.string ?? "(nil)"
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
                  - base id: \(baseId)
                  - localized article id: \(localizedFileRefId)
                """
            case let .questionnaire(.missingField(fileRef, itemIdx, fieldName)):
                if let itemIdx {
                    "Questionnaire '\(fileRef.filenameIncludingLocalization)': item \(itemIdx) is missing value for field '\(fieldName)'"
                } else {
                    "Questionnaire '\(fileRef.filenameIncludingLocalization)': missing value for field '\(fieldName)'"
                }
            case let .questionnaire(.invalidField(fileRef, itemIdx, fieldName, fieldValue, failureReason)):
                if let itemIdx {
                    "Questionnaire '\(fileRef.filenameIncludingLocalization)': item \(itemIdx) has invalid value for field '\(fieldName)': \(desc(fieldValue)). \(failureReason)"
                } else {
                    "Questionnaire '\(fileRef.filenameIncludingLocalization)': invalid value for field '\(fieldName)': \(desc(fieldValue)). \(failureReason)"
                }
            case let .questionnaire(.mismatchingFieldValues(baseFileRef, localizedFileRef, itemIdx, fieldName, baseValue, localizedValue)):
                """
                Localized Questionnaire: item field value does not match base localization
                  - base questionnaire: \(baseFileRef.filenameIncludingLocalization)
                  - localized questionnaire: \(localizedFileRef.filenameIncludingLocalization)
                  - item idx: \(itemIdx.map(String.init) ?? "n/a")
                  - fieldName: \(fieldName)
                  - base questionnaire value: \(desc(baseValue))
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
        issues.append(contentsOf: try validateQuestionnaires())
        return issues
    }
    
    
    private func validateQuestionnaires() throws -> [BundleValidationIssue] { // swiftlint:disable:this function_body_length
        let questionnaireFileRefs = studyDefinition.components.compactMap {
            switch $0 {
            case .questionnaire(let component):
                component.fileRef
            default:
                nil
            }
        }
        let fileManager = FileManager.default
        var issues: [BundleValidationIssue] = []
        for fileRef in questionnaireFileRefs {
            /// all files for this fileRef's category
            let urls = (try? fileManager.contentsOfDirectory(
                at: Self.folderUrl(for: fileRef.category, relativeTo: bundleUrl),
                includingPropertiesForKeys: nil
            )) ?? []
            let candidates = LocalizedFileResolution.selectCandidatesIgnoringLocalization(
                matching: LocalizedFileResource(fileRef),
                from: urls
            )
            let questionnaires = try candidates.map {
                (questionnaire: try JSONDecoder().decode(Questionnaire.self, from: try Data(contentsOf: $0.url)), fileRef: $0)
            }
            func checkSingleQuestionnaire( // swiftlint:disable:this function_body_length
                _ questionnaire: Questionnaire,
                fileRef questionnaireFileRef: LocalizedFileResource.Resolved
            ) {
                if questionnaire.id?.value == nil {
                    issues.append(.questionnaire(.missingField(
                        fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                        itemIdx: nil,
                        fieldName: "id"
                    )))
                }
                if let questionnaireLangRaw = questionnaire.language?.value?.string, !questionnaireLangRaw.isEmpty {
                    if let questionnaireKey = LocalizationKey(questionnaireLangRaw) {
                        let fileRefKey = questionnaireFileRef.localization
                        if questionnaireKey != fileRefKey {
                            issues.append(.questionnaire(.languageDiffersFromFilenameLocalization(
                                fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                                questionnaireLanguage: questionnaireKey.description
                            )))
                        }
                    } else {
                        // the questionnaire does have a `language` value, but we were unable to parse it into a `LocalizationKey`.
                        issues.append(.questionnaire(.invalidField(
                            fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                            itemIdx: nil,
                            fieldName: "language",
                            fieldValue: .init(questionnaireLangRaw),
                            failureReason: "failed to parse into a `LocalizationKey`"
                        )))
                    }
                } else {
                    issues.append(.questionnaire(.missingField(
                        fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                        itemIdx: nil,
                        fieldName: "language"
                    )))
                }
                if questionnaire.title?.value == nil {
                    issues.append(.questionnaire(.missingField(
                        fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                        itemIdx: nil,
                        fieldName: "title"
                    )))
                }
                guard let items = questionnaire.item else {
                    issues.append(.questionnaire(.missingField(
                        fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                        itemIdx: nil,
                        fieldName: "item"
                    )))
                    return
                }
                for (idx, item) in items.enumerated() {
                    func checkHasValue(_ keyPath: KeyPath<QuestionnaireItem, (some Any)?>, _ name: String) {
                        if item[keyPath: keyPath] == nil {
                            issues.append(.questionnaire(.missingField(
                                fileRef: .init(fileRef: fileRef, localization: questionnaireFileRef.localization),
                                itemIdx: idx,
                                fieldName: name
                            )))
                        }
                    }
                    checkHasValue(\.linkId.value, "linkId")
                    checkHasValue(\.text?.value, "text")
                }
            }
            let base = questionnaires.first { $0.0.language == "en-US" || $0.fileRef.localization == .enUS }
                ?? questionnaires.first { $0.0.language == "en" || $0.fileRef.localization.language.isEquivalent(to: .init(identifier: "en")) }
                ?? questionnaires.first! // swiftlint:disable:this force_unwrapping - SAFETY: we have checked above that this is non-empty
            checkSingleQuestionnaire(base.questionnaire, fileRef: base.fileRef)
            for other in questionnaires.filter({ $0.fileRef != base.fileRef }) {
                checkSingleQuestionnaire(other.questionnaire, fileRef: other.fileRef)
                if base.questionnaire.id?.value?.string != other.questionnaire.id?.value?.string {
                    issues.append(.questionnaire(.mismatchingFieldValues(
                        baseFileRef: .init(fileRef: fileRef, localization: base.fileRef.localization),
                        localizedFileRef: .init(fileRef: fileRef, localization: other.fileRef.localization),
                        itemIdx: nil,
                        fieldName: "id",
                        baseValue: .init(base.questionnaire.id?.value?.string),
                        localizedValue: .init(other.questionnaire.id?.value?.string)
                    )))
                }
                let baseItems = base.questionnaire.item ?? []
                let otherItems = other.questionnaire.item ?? []
                guard baseItems.count == otherItems.count else {
                    issues.append(.questionnaire(.mismatchingFieldValues(
                        baseFileRef: .init(fileRef: fileRef, localization: base.fileRef.localization),
                        localizedFileRef: .init(fileRef: fileRef, localization: other.fileRef.localization),
                        itemIdx: nil,
                        fieldName: "item.length",
                        baseValue: .init(baseItems.count),
                        localizedValue: .init(otherItems.count)
                    )))
                    continue
                }
                for (idx, (baseItem, item)) in zip(baseItems, otherItems).enumerated() {
                    func checkEqual(_ keyPath: KeyPath<QuestionnaireItem, (some Hashable & Sendable)?>, _ name: String) {
                        let baseValue = baseItem[keyPath: keyPath]
                        let itemValue = item[keyPath: keyPath]
                        if baseValue != itemValue {
                            issues.append(.questionnaire(.mismatchingFieldValues(
                                baseFileRef: .init(fileRef: fileRef, localization: base.fileRef.localization),
                                localizedFileRef: .init(fileRef: fileRef, localization: other.fileRef.localization),
                                itemIdx: idx,
                                fieldName: name,
                                baseValue: .init(baseValue),
                                localizedValue: .init(itemValue)
                            )))
                        }
                    }
                    checkEqual(\.linkId.value, "linkId")
                    checkEqual(\.type.value, "type")
                }
            }
        }
        return issues
    }
    
    
    private func validateArticles() throws -> [BundleValidationIssue] { // swiftlint:disable:this function_body_length
        let articleFileRefs = studyDefinition.components.compactMap {
            switch $0 {
            case .informational(let component):
                component.fileRef
            default:
                nil
            }
        }
        let fileManager = FileManager.default
        var issues: [BundleValidationIssue] = []
        for articleFileRef in articleFileRefs {
            /// all files for this fileRef's category
            let urls = (try? fileManager.contentsOfDirectory(
                at: Self.folderUrl(for: articleFileRef.category, relativeTo: bundleUrl),
                includingPropertiesForKeys: nil
            )) ?? []
            let candidates = LocalizedFileResolution.selectCandidatesIgnoringLocalization(
                matching: LocalizedFileResource(articleFileRef),
                from: urls
            )
            guard !candidates.isEmpty else {
                issues.append(.general(.noFilesMatchingFileRef(articleFileRef)))
                continue
            }
            let documents = try candidates.map {
                (document: try MarkdownDocument(processingContentsOf: $0.url), fileRef: $0)
            }
            let baseDocument = documents.first { $0.fileRef.localization == .enUS }
                ?? documents.first { $0.fileRef.localization.language.isEquivalent(to: .init(identifier: "en")) }
                ?? documents.first! // swiftlint:disable:this force_unwrapping - SAFETY: we have checked above that this is non-empty
            for (document, fileRef) in documents {
                guard let docId = document.metadata["id"] else {
                    issues.append(.article(.documentMetadataMissingId(
                        fileRef: .init(fileRef: articleFileRef, localization: fileRef.localization)
                    )))
                    continue
                }
                guard let baseId = baseDocument.document.metadata["id"] else {
                    issues.append(.article(.documentMetadataMissingId(
                        fileRef: .init(fileRef: articleFileRef, localization: baseDocument.fileRef.localization)
                    )))
                    continue
                }
                guard docId == baseId else {
                    issues.append(.article(.documentMetadataIdMismatchToBase(
                        baseLocalization: .init(fileRef: articleFileRef, localization: baseDocument.fileRef.localization),
                        localizedFileRef: .init(fileRef: articleFileRef, localization: fileRef.localization),
                        baseId: baseId,
                        localizedFileRefId: docId
                    )))
                    continue
                }
            }
        }
        return issues
    }
}


extension LocalizedFileResource {
    init(_ other: StudyBundle.FileReference, locale: Locale = .autoupdatingCurrent) {
        self.init("\(other.category.rawValue)/\(other.filename).\(other.fileExtension)", locale: locale)
    }
}


extension QuestionnaireItemType: @retroactive @unchecked Sendable {}

extension Equatable {
    fileprivate func isEqual(_ other: Any) -> Bool {
        if let other = other as? Self {
            self == other
        } else {
            false
        }
    }
}
