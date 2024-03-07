//
// This source file is part of the Neurodevelopment Assessment and Monitoring System (NAMS) project
//
// SPDX-FileCopyrightText: 2024 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ByteCoding
import NIO


/// A data record of a EDF/BDF file.
public struct DataRecord<S: Sample> {
    /// The list of channels.
    public let channels: [Channel<S>]


    /// Create a new data record.
    /// - Parameter channels: The list of channels.
    public init(channels: [Channel<S>]) {
        self.channels = channels
    }
}


extension DataRecord: ByteEncodable {
    public func encode(to byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness) {
        for channel in channels {
            channel.encode(to: &byteBuffer, preferredEndianness: endianness)
        }
    }
}
