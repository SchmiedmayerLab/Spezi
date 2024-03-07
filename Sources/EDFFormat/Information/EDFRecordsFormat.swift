//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// The data record format of an EDF file.
public enum EDFRecordsFormat {
    /// EDF file with continuous recording: `EDF+C`.
    case contiguousRecording
    /// EDF file with interrupted recording: `EDF+D`.
    case interruptedRecording
    /// Custom value for the reserved field.
    case custom(_ string: String = "")
}
