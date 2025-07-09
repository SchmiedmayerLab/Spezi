//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation


extension Localization {
    private struct ScoredCandidate: Hashable, Comparable, Sendable {
        let fileResource: LocalizedFileResource
        let score: Double
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.score < rhs.score
        }
    }
    
    /// Resolves a localized resource from a set of inputs, based on an unlocalizdd filename and a target locale.
    public static func resolveFile(
        named unlocalizedFilename: String,
        from candidates: some Collection<URL>,
        locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .preferLanguageMatch,
        fallback fallbackLocale: LocalizationKey? = .enUS
    ) -> LocalizedFileResource? {
        let candidates: [ScoredCandidate] = candidates
            .lazy
            .compactMap { Self.parseLocalizedFileResource(from: $0) }
            .filter { $0.url.matches(unlocalizedFilename: unlocalizedFilename) }
            .map { ScoredCandidate(fileResource: $0, score: $0.localization.score(against: locale, using: localeMatchingBehaviour)) }
            .sorted(by: >)
        guard let candidate = candidates.first, candidate.score > 0.5 else {
            Self.logger.error("Unable to find url for \(unlocalizedFilename) and locale \(locale) (key: \(LocalizationKey(locale: locale))).")
            if candidates.isEmpty {
                Self.logger.error("No candidates")
            } else {
                Self.logger.error("Candidates:")
                for candidate in candidates {
                    Self.logger.error("- \(candidate.score) @ \(candidate.fileResource.fullFilenameIncludingLocalization)")
                }
            }
            if let fallbackLocale, let fallback = candidates.first(where: { $0.fileResource.localization == fallbackLocale }) {
                Self.logger.warning("Falling back to \(fallbackLocale) locale.")
                return fallback.fileResource
            }
            return nil
        }
        do {
            // SAFETY: we've checked above that there is at least one element in the array.
            // swiftlint:disable:next force_unwrapping
            let equallyBestRanked = candidates.chunked(by: { $0.score == $1.score }).first!
            guard equallyBestRanked.count == 1 else {
                Self.logger.error("Candidates:")
                for candidate in candidates {
                    Self.logger.error("- \(candidate.score) @ \(candidate.fileResource.fullFilenameIncludingLocalization)")
                }
                fatalError("Found multiple candidates, all of which are equally ranked!")
            }
        }
        return candidate.fileResource
    }
}


extension Localization {
    /// Information about a File's localization.
    public struct LocalizedFileResource: Hashable, Sendable {
        /// The (localized) URL of the file.
        public let url: URL
        /// The URL's file name (including the file extension), with the localization suffix removed.
        public let unlocalizedFilename: String
        /// The localization info extracted from the localized filename's localization suffix.
        public let localization: LocalizationKey
        
        public var fullFilenameIncludingLocalization: String {
            guard let baseNameEndIdx = unlocalizedFilename.firstIndex(of: ".") else {
                return unlocalizedFilename
            }
            return "\(unlocalizedFilename[..<baseNameEndIdx])+\(localization)\(unlocalizedFilename[baseNameEndIdx...])"
        }
    }
    
    
    /// Creates a new `LocalizedFileResource` by parsing a URL pointing to a localized file resource.
    public static func parseLocalizedFileResource(from url: URL) -> LocalizedFileResource? {
        guard let components = url.lastPathComponent.parseLocalizationComponents(),
              let fileExtension = components.fileExtension,
              let localization = LocalizationKey(components.rawLocalization) else {
            return nil
        }
        return .init(url: url, unlocalizedFilename: "\(components.baseName).\(fileExtension)", localization: localization)
    }
}


extension LocalizationKey {
    /// Creates a new `LocalizationKey` by extracting a localization suffix from a filename
    public init?(parsingFilename filename: String) {
        guard let parseResult = Localization.parseLocalizedFileResource(from: URL(filePath: filename)) else {
            return nil
        }
        self = parseResult.localization
    }
}


extension URL {
    fileprivate func matches(unlocalizedFilename: String) -> Bool {
        self.strippingLocalizationSuffix().pathComponents.ends(with: unlocalizedFilename.split(separator: "/"), by: ==)
    }
    
    /// Returns a copy of the URL, with a potential loalization suffix removed.
    func strippingLocalizationSuffix() -> URL {
        guard let components = self.lastPathComponent.parseLocalizationComponents() else {
            return self
        }
        var newUrl = self.deletingLastPathComponent().appending(component: components.baseName)
        if let fileExtension = components.fileExtension {
            newUrl.appendPathExtension(fileExtension)
        }
        return newUrl
    }
}


extension StringProtocol {
    fileprivate func parseLocalizationComponents() -> (baseName: String, fileExtension: String?, rawLocalization: String)? {
        // swiftlint:disable:previous large_tuple
        guard let separatorIdx = self.lastIndex(of: "+") else {
            return nil
        }
        var filename = self[...]
        let baseName = String(filename[..<separatorIdx])
        filename.removeFirst(baseName.count + 1)
        guard let fileExtIdx = filename.firstIndex(of: ".") else {
            return (baseName, nil, String(filename))
        }
        let rawLocalization = String(filename[..<fileExtIdx])
        filename.removeFirst(rawLocalization.count + 1)
        let fileExtension = String(filename)
        return (baseName, fileExtension, rawLocalization)
    }
}

extension BidirectionalCollection {
    /// Determines whether the collection ends with the elements of another collection.
    public func ends(
        with possibleSuffix: some BidirectionalCollection<Element>
    ) -> Bool where Element: Equatable {
        ends(with: possibleSuffix, by: ==)
    }
    
    /// Determines whether the collection ends with the elements of another collection.
    public func ends<PossibleSuffix: BidirectionalCollection, E: Error>(
        with possibleSuffix: PossibleSuffix,
        by areEquivalent: (Element, PossibleSuffix.Element) throws(E) -> Bool
    ) throws(E) -> Bool {
        guard self.count >= possibleSuffix.count else {
            return false
        }
        for (elem1, elem2) in zip(self.reversed(), possibleSuffix.reversed()) {
            guard try areEquivalent(elem1, elem2) else {
                return false
            }
        }
        return true
    }
}
