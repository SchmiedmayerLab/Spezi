//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable function_body_length

import Foundation
import ModelsR4
import SpeziFoundation
import SpeziLocalization
@_spi(APISupport)
@testable import SpeziStudyDefinition
import Testing


@Suite
struct StudyBundleValidationTests { // swiftlint:disable:this type_body_length
    @Test
    func validInput() throws {
        let testStudy = StudyDefinition(
            studyRevision: 0,
            metadata: .init(
                id: UUID(),
                title: "",
                explanationText: "",
                shortExplanationText: "",
                participationCriterion: true,
                enrollmentConditions: .none
            ),
            components: [
                .informational(.init(
                    id: UUID(),
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md")
                )),
                .questionnaire(.init(
                    id: UUID(),
                    fileRef: .init(category: .questionnaire, filename: "Valid", fileExtension: "json")
                ))
            ],
            componentSchedules: []
        )
        let tmpUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
        defer {
            try? FileManager.default.removeItem(at: tmpUrl)
        }
        // this not failing means that the validation successfully ran, and found no issues.
        _ = try StudyBundle.writeToDisk(
            at: tmpUrl,
            definition: testStudy,
            files: [
                StudyBundle.FileInput(
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"),
                    localization: .init(language: .english, region: .unitedStates),
                    contents: """
                        ---
                        title: Welcome to our Study!
                        id: 4A6A052E-5FE6-4FFA-92D5-DA605E12E97E
                        ---
                        """
                ),
                StudyBundle.FileInput(
                    fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"),
                    localization: .init(language: .spanish, region: .unitedStates),
                    contents: """
                        ---
                        title: Bienvenido a nuestro estudio!
                        id: 4A6A052E-5FE6-4FFA-92D5-DA605E12E97E
                        ---
                        """
                ),
                StudyBundle.FileInput(
                    fileRef: .init(category: .questionnaire, filename: "Valid", fileExtension: "json"),
                    localization: .enUS,
                    contentsOf: try #require(Bundle.module.url(forResource: "Valid+en-US", withExtension: "json"))
                ),
                StudyBundle.FileInput(
                    fileRef: .init(category: .questionnaire, filename: "Valid", fileExtension: "json"),
                    localization: .enGB,
                    contentsOf: try #require(Bundle.module.url(forResource: "Valid+en-UK", withExtension: "json"))
                )
            ]
        )
    }
    
    
    @Test
    func invalidArticleInputMissingId() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeStudyForArticleValidation(
                enUSExtraMetadata: [],
                esUSExtraMetadata: []
            )
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .informationalArticle, filename: "a1", fileExtension: "md")
            #expect(issues == [
                .article(.documentMetadataMissingId(fileRef: .init(fileRef: fileRef, localization: .enUS))),
                .article(.documentMetadataMissingId(fileRef: .init(fileRef: fileRef, localization: .esUS)))
            ])
        default:
            throw error
        }
    }
    
    @Test
    func invalidArticleInputMismatchedId() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeStudyForArticleValidation(
                enUSExtraMetadata: [("id", "A5958A33-D93E-49D5-A0C6-3708CA97D431")],
                esUSExtraMetadata: [("id", "1EED6D54-1462-4DAC-9ED9-D39AE9CE01DB")]
            )
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .informationalArticle, filename: "a1", fileExtension: "md")
            #expect(issues == [
                .article(.documentMetadataIdMismatchToBase(
                    baseLocalization: .init(fileRef: fileRef, localization: .enUS),
                    localizedFileRef: .init(fileRef: fileRef, localization: .esUS),
                    baseId: "A5958A33-D93E-49D5-A0C6-3708CA97D431",
                    localizedFileRefId: "1EED6D54-1462-4DAC-9ED9-D39AE9CE01DB"
                ))
            ])
        default:
            throw error
        }
    }
    
    
    // test that we expect the questionnaire's language field to be equal to the language in the filename's localization component.
    @Test
    func questionnaireLocalizationLanguageMismatch() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeTestStudy(articles: [], questionnaires: [
                .init(fileRef: .init(category: .questionnaire, filename: "Invalid3", fileExtension: "json"), localizations: [
                    .init(key: .enUS, url: try #require(Bundle.module.url(forResource: "Invalid3+en-US", withExtension: "json"))),
                    .init(key: .enGB, url: try #require(Bundle.module.url(forResource: "Invalid3+en-UK", withExtension: "json")))
                ])
            ])
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: "Invalid3", fileExtension: "json")
            #expect(Set(issues) == [
                .questionnaire(.languageDiffersFromFilenameLocalization(
                    fileRef: .init(fileRef: fileRef, localization: .enGB),
                    questionnaireLanguage: "en-US"
                ))
            ])
        default:
            throw error
        }
    }
    
    
    // test that we expect the questionnaire's language field to be parsable into a `LocalizationKey`.
    @Test
    func questionnaireInvalidLocalization() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeTestStudy(articles: [], questionnaires: [
                .init(fileRef: .init(category: .questionnaire, filename: "Invalid4", fileExtension: "json"), localizations: [
                    .init(key: .esUS, url: try #require(Bundle.module.url(forResource: "Invalid4+es-US", withExtension: "json")))
                ])
            ])
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: "Invalid4", fileExtension: "json")
            #expect(Set(issues) == [
                .questionnaire(.invalidField(
                    fileRef: .init(fileRef: fileRef, localization: .esUS),
                    itemIdx: nil,
                    fieldName: "language",
                    fieldValue: .init("es"),
                    failureReason: "failed to parse into a `LocalizationKey`"
                ))
            ])
        default:
            throw error
        }
    }
    
    
    @Test
    func invalidQuestionnaireLocalizations() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeTestStudy(articles: [], questionnaires: [
                .init(fileRef: .init(category: .questionnaire, filename: "Invalid1", fileExtension: "json"), localizations: [
                    .init(key: .enUS, url: try #require(Bundle.module.url(forResource: "Invalid1+en-US", withExtension: "json"))),
                    .init(key: .enGB, url: try #require(Bundle.module.url(forResource: "Invalid1+en-UK", withExtension: "json")))
                ])
            ])
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: "Invalid1", fileExtension: "json")
            #expect(Set(issues) == [
                .questionnaire(.mismatchingFieldValues(
                    baseFileRef: .init(fileRef: fileRef, localization: .enUS),
                    localizedFileRef: .init(fileRef: fileRef, localization: .enGB),
                    itemIdx: nil,
                    fieldName: "id",
                    baseValue: .init("0C0D66EB-DF6E-43CA-B8E6-8653DB5D1610"),
                    localizedValue: .init("C8F9D485-3A88-4416-92EE-839CC1974AFC")
                )),
                .questionnaire(.mismatchingFieldValues(
                    baseFileRef: .init(fileRef: fileRef, localization: .enUS),
                    localizedFileRef: .init(fileRef: fileRef, localization: .enGB),
                    itemIdx: 2,
                    fieldName: "type",
                    baseValue: .init(QuestionnaireItemType.date),
                    localizedValue: .init(QuestionnaireItemType.integer)
                ))
            ])
        default:
            throw error
        }
    }
    
    
    @Test
    func invalidQuestionnaireLocalizations2() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeTestStudy(articles: [], questionnaires: [
                .init(fileRef: .init(category: .questionnaire, filename: "Invalid2", fileExtension: "json"), localizations: [
                    .init(key: .enUS, url: try #require(Bundle.module.url(forResource: "Invalid2+en-US", withExtension: "json"))),
                    .init(key: .enGB, url: try #require(Bundle.module.url(forResource: "Invalid2+en-UK", withExtension: "json")))
                ])
            ])
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: "Invalid2", fileExtension: "json")
            #expect(Set(issues) == [
                .questionnaire(.missingField(
                    fileRef: .init(fileRef: fileRef, localization: .enGB),
                    itemIdx: nil,
                    fieldName: "id"
                )),
                .questionnaire(.mismatchingFieldValues(
                    baseFileRef: .init(fileRef: fileRef, localization: .enUS),
                    localizedFileRef: .init(fileRef: fileRef, localization: .enGB),
                    itemIdx: nil,
                    fieldName: "id",
                    baseValue: .init("0C0D66EB-DF6E-43CA-B8E6-8653DB5D1610"),
                    localizedValue: nil
                )),
                .questionnaire(.missingField(
                    fileRef: .init(fileRef: fileRef, localization: .enUS),
                    itemIdx: nil,
                    fieldName: "title"
                )),
                .questionnaire(.missingField(
                    fileRef: .init(fileRef: fileRef, localization: .enUS),
                    itemIdx: 1,
                    fieldName: "text"
                ))
            ])
        default:
            throw error
        }
    }
    
    
    @Test
    func invalidQuestionnaireLocalizations3() throws {
        let error = try #require(throws: StudyBundle.CreateBundleError.self) {
            try makeTestStudy(articles: [], questionnaires: [
                .init(fileRef: .init(category: .questionnaire, filename: "Empty", fileExtension: "json"), localizations: [
                    .init(key: .enUS, url: try #require(Bundle.module.url(forResource: "Empty+en-US", withExtension: "json"))),
                    .init(key: .enGB, url: try #require(Bundle.module.url(forResource: "Empty+en-UK", withExtension: "json")))
                ])
            ])
        }
        switch error {
        case .failedValidation(let issues):
            let fileRef = StudyBundle.FileReference(category: .questionnaire, filename: "Empty", fileExtension: "json")
            #expect(Set(issues) == [
                .questionnaire(.missingField(
                    fileRef: .init(fileRef: fileRef, localization: .enUS),
                    itemIdx: nil,
                    fieldName: "item"
                )),
                .questionnaire(.mismatchingFieldValues(
                    baseFileRef: .init(fileRef: fileRef, localization: .enUS),
                    localizedFileRef: .init(fileRef: fileRef, localization: .enGB),
                    itemIdx: nil,
                    fieldName: "item.length",
                    baseValue: .init(0),
                    localizedValue: .init(1)
                ))
            ])
        default:
            throw error
        }
    }
    
    
    @Test
    func missingFileRef() throws {
        let definition = StudyDefinition(
            studyRevision: 0,
            metadata: .init(
                id: UUID(),
                title: "",
                explanationText: "",
                shortExplanationText: "",
                participationCriterion: true,
                enrollmentConditions: .none
            ),
            components: [
                .informational(.init(
                    id: UUID(),
                    fileRef: .init(category: .informationalArticle, filename: "Article", fileExtension: "md")
                ))
            ],
            componentSchedules: []
        )
        do {
            let tmpUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
            defer {
                try? FileManager.default.removeItem(at: tmpUrl)
            }
            let error = try #require(throws: (StudyBundle.CreateBundleError).self) {
                try StudyBundle.writeToDisk(at: tmpUrl, definition: definition, files: [])
            }
            switch error {
            case .failedValidation(let issues):
                #expect(Set(issues) == [
                    .general(.noFilesMatchingFileRef(.init(category: .informationalArticle, filename: "Article", fileExtension: "md")))
                ])
            default:
                throw error
            }
        }
    }
}


// MARK: Utils

extension StudyBundleValidationTests {
    private struct TestStudyArticleInput {
        struct Localization {
            let key: LocalizationKey
            let contents: String
        }
        let fileRef: StudyBundle.FileReference
        let localizations: [Localization]
    }
    
    private struct TestStudyQuestionnaireInput {
        struct Localization {
            let key: LocalizationKey
            let url: URL
        }
        let fileRef: StudyBundle.FileReference
        let localizations: [Localization]
    }
    
    private func makeTestStudy(
        articles: [TestStudyArticleInput],
        questionnaires: [TestStudyQuestionnaireInput]
    ) throws -> StudyBundle {
        let testStudy = StudyDefinition(
            studyRevision: 0,
            metadata: .init(
                id: UUID(),
                title: "",
                explanationText: "",
                shortExplanationText: "",
                participationCriterion: true,
                enrollmentConditions: .none
            ),
            components: Array {
                for article in articles {
                    .informational(.init(id: UUID(), fileRef: article.fileRef))
                }
                for questionnaire in questionnaires {
                    .questionnaire(.init(id: UUID(), fileRef: questionnaire.fileRef))
                }
            },
            componentSchedules: []
        )
        let tmpUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .speziStudyBundle)
        defer {
            try? FileManager.default.removeItem(at: tmpUrl)
        }
        func makeArticle1(localization: LocalizationKey, metadata: [(String, String)]) throws -> StudyBundle.FileInput {
            try StudyBundle.FileInput(
                fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"),
                localization: localization,
                contents: { () -> String in
                    let metadata = metadata.map { "\($0): \($1)" }.joined(separator: "\n")
                    return metadata.isEmpty ? "---\n---" : "---\n\(metadata)\n---"
                }()
            )
        }
        return try StudyBundle.writeToDisk(
            at: tmpUrl,
            definition: testStudy,
            files: try Array {
                for article in articles {
                    for localization in article.localizations {
                        try StudyBundle.FileInput(fileRef: article.fileRef, localization: localization.key, contents: localization.contents)
                    }
                }
                for questionnaire in questionnaires {
                    for localization in questionnaire.localizations {
                        try StudyBundle.FileInput(fileRef: questionnaire.fileRef, localization: localization.key, contentsOf: localization.url)
                    }
                }
            }
        )
    }
    
    
    /// Creates a temporary study bundle for testing article validation
    private func makeStudyForArticleValidation(
        enUSExtraMetadata: [(String, String)],
        esUSExtraMetadata: [(String, String)]
    ) throws -> StudyBundle {
        func makeArticleLocalization(for key: LocalizationKey, metadata: [(String, String)]) -> TestStudyArticleInput.Localization {
            var lines = ["---"]
            for (key, value) in metadata {
                lines.append("\(key): \(value)")
            }
            lines.append("---")
            return .init(key: key, contents: lines.joined(separator: "\n") + "\n")
        }
        return try makeTestStudy(
            articles: [
                .init(fileRef: .init(category: .informationalArticle, filename: "a1", fileExtension: "md"), localizations: [
                    makeArticleLocalization(for: .enUS, metadata: [("title", "Welcome to our Study!")] + enUSExtraMetadata),
                    makeArticleLocalization(for: .esUS, metadata: [("title", "Bienvenido a nuestro estudio!")] + esUSExtraMetadata)
                ])
            ],
            questionnaires: []
        )
    }
}


extension LocalizationKey {
    static let esUS = Self(language: .spanish, region: .unitedStates)
    static let enGB = Self(language: .english, region: .unitedKingdom)
}
