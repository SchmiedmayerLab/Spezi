//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import ByteCoding
import Foundation
import NIO


enum FileRecordsFormat {
    /// Only valid for BDF Files
    case bits24
    /// Biosemi file encoded as a EDF file.
    case biosemi
    /// EDF file with continuous recording: `EDF+C`.
    case contiguousRecording
    /// EDF file with interrupted recording: `EDF+D`.
    case interruptedRecording
    /// Custom value for the reserved field.
    case custom(_ string: String = "")
}


extension FileRecordsFormat {
    init(from format: EDFRecordsFormat) {
        switch format {
        case .contiguousRecording:
            self = .contiguousRecording
        case .interruptedRecording:
            self = .interruptedRecording
        case let .custom(string):
            self = .custom(string)
        }
    }
}


extension FileRecordsFormat: RawRepresentable {
    var rawValue: String {
        switch self {
        case .bits24:
            "24BIT"
        case .biosemi:
            "BIOSEMI"
        case .contiguousRecording:
            "EDF+C"
        case .interruptedRecording:
            "EDF+D"
        case let .custom(string):
            string
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "24BIT":
            self = .bits24
        case "BIOSEMI":
            self = .biosemi
        case "EDF+C":
            self = .contiguousRecording
        case "EDF+D":
            self = .interruptedRecording
        default:
            self = .custom(rawValue)
        }
    }
}


extension FileRecordsFormat: ByteEncodable {
    public func encode(to byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness) {
        byteBuffer.writeEDFAscii(rawValue, length: 44)
    }
}
