//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import NIO


extension String: PrimitiveByteCodable {
    /// Decodes an utf8 string from its byte representation.
    ///
    /// Decodes an utf8 string from a `ByteBuffer`.
    ///
    /// - Note: This implementation assumes that all bytes in the ByteBuffer are representing
    ///     the string.
    /// - Parameters
    ///   - byteBuffer: The ByteBuffer to decode from.
    ///   - endianness: The preferred endianness to use for decoding if applicable.
    ///     This is unused with the String implementation.
    public init?(from byteBuffer: inout ByteBuffer, endianness: Endianness) {
        guard let string = byteBuffer.readString(length: byteBuffer.readableBytes) else {
            return nil
        }

        self = string
    }

    /// Encodes an utf8 string to its byte representation.
    ///
    /// Encodes an utf8 string into a `ByteBuffer`.
    ///
    /// - Parameters
    ///   - byteBuffer: The ByteBuffer to write to.
    ///   - endianness: The preferred endianness to use for decoding if applicable.
    ///     This is unused with the String implementation.
    public func encode(to byteBuffer: inout ByteBuffer, endianness: Endianness) {
        byteBuffer.writeString(self)
    }
}
