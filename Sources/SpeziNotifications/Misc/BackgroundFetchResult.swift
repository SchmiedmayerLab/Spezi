//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if os(iOS) || os(visionOS) || os(tvOS) || os(watchOS)
// BackgroundFetchResult type-alias is currently defined in Spezi. Once Spezi removes it and makes a breaking change, we can move it to this package.
@_exported import typealias Spezi.BackgroundFetchResult
#endif
