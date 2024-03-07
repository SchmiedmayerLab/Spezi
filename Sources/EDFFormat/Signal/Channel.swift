//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import ByteCoding
import NIO


/// Recorded data of a channel.
public struct Channel<S: Sample> {
    /// The list of samples.
    public let samples: [S]


    /// Create a new channel data
    /// - Parameter samples: The list of samples.
    public init(samples: [S]) {
        self.samples = samples
    }
}


extension Channel: ByteEncodable {
    public func encode(to byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness) {
        for sample in samples {
            sample.encode(to: &byteBuffer, preferredEndianness: endianness)
        }
    }
}
