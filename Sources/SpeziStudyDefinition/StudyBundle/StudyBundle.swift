//
// This source file is part of the My Heart Counts iOS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import class ModelsR4.Questionnaire
import OSLog
import SpeziFoundation
import SpeziLocalization
import UniformTypeIdentifiers


extension UTType {
    /// A Study Bundle package.
    public static let speziStudyBundle = UTType(filenameExtension: "spezistudybundle", conformingTo: .package)!
    // swiftlint:disable:previous force_unwrapping
}


/// A handle for working with a Study Definition bundle.
///
/// - Important: A ``StudyBundle`` represents an immutable resource; mutating the underlying file system item is not allowed and will result in undefined behaviour.
///     If you wish to make changes to a ``StudyBundle``, create a new bundle using the ``StudyBundle/writeToDisk(at:definition:files:)`` function,
///     or use ``copy(to:)`` to create a copy of the bundle's underlying file system item.
///
/// ## Topics
///
/// ### Initializers
/// - ``init(bundleUrl:)``
/// - ``StudyBundleError``
///
/// ### Instance Properties
/// - ``bundleUrl``
/// - ``studyDefinition``
///
/// ### Accessing the Bundle's Contents
/// - ``consentText(for:in:using:)``
/// - ``questionnaire(for:in:using:)``
/// - ``displayTitle(for:in:using:)``
/// - ``resolve(_:in:using:)``
///
/// ### Operations
/// - ``copy(to:)``
///
/// ### Creating Study Bundles
/// - ``writeToDisk(at:definition:files:)``
/// - ``FileInput``
/// - ``CreateBundleError``
///
/// ### Other
/// - ``fileExtension``
/// - ``FileReference``
/// - ``LocalizationKey``
public struct StudyBundle: Identifiable, Sendable {
    public enum StudyBundleError: Error {
        /// The URL passed to an operation does not point to a study bundle package.
        case notValidStudyBundleUrl
    }
    
    /// The file extension used by Study Bundles.
    public static let fileExtension = "spezistudybundle"
    static let logger = Logger(subsystem: "edu.stanford.SpeziStudy", category: "StudyBundle")
    
    /// The file url of the study definition bundle.
    public let bundleUrl: URL
    /// The bundle's ``StudyDefinition``
    public let studyDefinition: StudyDefinition
    
    public var id: UUID { studyDefinition.id }
    
    /// Read a study bundle from disk.
    public init(bundleUrl: URL) throws {
        try Self.assertIsStudyBundleUrl(bundleUrl)
        self.bundleUrl = bundleUrl
        do {
            let data = try Data(contentsOf: bundleUrl.appendingPathComponent("definition", conformingTo: .json))
            self.studyDefinition = try JSONDecoder().decode(
                StudyDefinition.self,
                from: data,
                configuration: .init(allowTrivialSchemaMigrations: true)
            )
        }
    }
    
    
    /// Writes a copy of the study bundle to the specified url.
    ///
    /// - parameter dstUrl: The url the study bundle should be written to. Note that this must be a valid url for a study bundle, i.e. it must use the ``StudyBundle/fileExtension``
    public func copy(to dstUrl: URL) throws {
        try Self.assertIsStudyBundleUrl(dstUrl)
        try FileManager.default.copyItem(at: bundleUrl, to: dstUrl, overwriteExisting: true)
    }
    
    
    /// Load a questionnaire resource from a ``FileReference``.
    public func questionnaire(
        for fileRef: FileReference,
        in locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .default
    ) -> Questionnaire? {
        _decodeResource(for: fileRef, locale: locale, using: localeMatchingBehaviour) {
            try JSONDecoder().decode(Questionnaire.self, from: $0)
        }
    }
    
    /// Load a the quesrionnaire resource with the specified filename.
    public func questionnaire(
        named questionnaireName: String,
        in locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .default
    ) -> Questionnaire? {
        questionnaire(
            for: .init(category: .questionnaire, filename: questionnaireName, fileExtension: "json"),
            in: locale,
            using: localeMatchingBehaviour
        )
    }
    
    /// Load a consent text resource from a ``FileReference``.
    public func consentText(
        for fileRef: FileReference,
        in locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .default
    ) -> String? {
        _decodeResource(for: fileRef, locale: locale, using: localeMatchingBehaviour) {
            String(data: $0, encoding: .utf8)
        }
    }
    
    
    private func _decodeResource<T>(
        for fileRef: FileReference,
        locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour,
        decode: (Data) throws -> T?
    ) -> T? {
        guard let url = resolve(fileRef: fileRef, locale: locale, localeMatchingBehaviour: localeMatchingBehaviour)?.url else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decode(data)
    }
}


extension StudyBundle {
    /// Throws an error if `url` isn't a valid study bundle url
    static func assertIsStudyBundleUrl(_ url: URL) throws(StudyBundleError) {
        guard url.hasDirectoryPath && url.pathExtension == Self.fileExtension else {
            throw .notValidStudyBundleUrl
        }
    }
}


extension StudyBundle: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bundleUrl == rhs.bundleUrl
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundleUrl)
    }
}
