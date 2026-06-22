//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziSpeechRecognizer
import SpeziSpeechSynthesizer


class TestAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            SpeechRecognizer()
            SpeechSynthesizer()
        }
    }
}
