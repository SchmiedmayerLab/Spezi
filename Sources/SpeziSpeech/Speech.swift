//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Observation
import Spezi


/// Spezi module to support speech-related features including text-to-speech and speech-to-text.
///
/// > Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) setup the core Spezi infrastructure.
/// 
/// The module needs to be registered in a Spezi-based application using the [`configuration`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate/configuration)
/// in a [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate):
/// ```swift
/// class ExampleAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             Speech()
///             // ...
///         }
///     }
/// }
/// ```
/// > Tip: You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).
///
///
/// ## Usage
///
/// ...
/// ```swift
/// ...
/// ```
@Observable
public class Speech: Module, DefaultInitializable {
    /// Creates an instance of a ``Speech`` module.
    public required init() { }
}
