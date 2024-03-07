//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Static information about an BDF(+)/EDF(+) file.
public struct FileInformation {
    /// The local subject identification for the recording.
    public let subject: SubjectIdentification
    /// The local recording identification.
    public let recording: RecordingIdentification
    /// The duration in seconds of a single data record.
    public let recordDuration: Int
}


extension FileInformation: Sendable {}


extension FileInformation {
    func verifyAsciiInputs() throws {
        try subject.verifyAsciiInputs()
        try recording.verifyAsciiInputs()
        try verifyAsciiInput(recordDuration, maxLength: 8, for: "recordDuration")
    }
}
