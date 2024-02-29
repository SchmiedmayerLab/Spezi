//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO


extension Data: ByteCodable {
    /// Decode a data blob.
    ///
    /// Copies all bytes from the ByteBuffer into a `Data` instance.
    /// - Parameters:
    ///   - byteBuffer: The ByteBuffer to decode from.
    ///   - endianness: The preferred endianness to use for decoding if applicable.
    ///     This is unused with the Data implementation.
    public init?(from byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness) {
        guard let data = byteBuffer.readData(length: byteBuffer.readableBytes) else {
            return nil
        }
        self = data
    }

    /// Encode a data blob.
    ///
    /// Copies the data instance into the ByteBuffer.
    /// - Parameters:
    ///   - byteBuffer: The ByteBuffer to write to.
    ///   - endianness: The preferred endianness to use for encoding if applicable.
    ///     This is unused with the Data implementation.
    public func encode(to byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness) {
        byteBuffer.writeData(self)
    }
}
