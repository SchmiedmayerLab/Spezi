//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIOCore
import NIOFoundationCompat


/// A type that is decodable from a byte representation.
///
/// Conforming types can be decoded from a `ByteBuffer´ assuming it holds
/// properly formatted binary data.
public protocol ByteDecodable {
    /// Decode the type from the `ByteBuffer`.
    ///
    /// Initialize a new instance using the byte representation provided by the `ByteBuffer`.
    /// This call should move the `readerIndex` forwards.
    ///
    /// - Note: Returns nil if no valid byte representation could be found.
    /// - Parameters:
    ///   - byteBuffer: The ByteBuffer to read from.
    ///   - endianness: The preferred endianness to use for decoding if applicable.
    ///     This might not apply to certain data structures that operate on single byte level.
    init?(from byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness)
}


/// A type that is decodable to a byte representation.
///
/// Conforming types can be encoded into a `ByteBuffer`.
public protocol ByteEncodable {
    /// Encode into the `ByteBuffer`.
    ///
    /// Encode the byte representation of this type into the provided `ByteBuffer`.
    /// This call should move the `writerIndex` forwards.
    ///
    /// - Parameters:
    ///   - byteBuffer: The ByteBuffer to write into.
    ///   - endianness: The preferred endianness to use for encoding if applicable.
    ///     This might not apply to certain data structures that operate on single byte level.
    func encode(to byteBuffer: inout ByteBuffer, preferredEndianness endianness: Endianness)
}


/// A type that is encodable to and decodable from and to a byte representation.
///
/// Conforming types can be encoded into or decodable from a `ByteBuffer`.
public typealias ByteCodable = ByteEncodable & ByteDecodable


extension ByteDecodable {
    /// Decode the type from the `ByteBuffer`.
    ///
    /// Initialize a new instance using the byte representation provided by the `ByteBuffer`.
    /// This call should move the `readerIndex` forwards.
    ///
    /// - Important: This uses `little` endianness as the default preferred endianness.
    ///
    /// - Note: Returns nil if no valid byte representation could be found.
    /// - Parameter byteBuffer: The ByteBuffer to read from.
    @_disfavoredOverload
    public init?(from byteBuffer: inout ByteBuffer) {
        self.init(from: &byteBuffer, preferredEndianness: .little)
    }
}


extension ByteEncodable {
    /// Encode into the `ByteBuffer`.
    ///
    /// Encode the byte representation of this type into the provided `ByteBuffer`.
    /// This call should move the `writerIndex` forwards.
    ///
    /// - Important: This uses `little` endianness as the default preferred endianness.
    ///
    /// - Parameter byteBuffer: The ByteBuffer to write into.
    @_disfavoredOverload
    public func encode(to byteBuffer: inout ByteBuffer) {
        self.encode(to: &byteBuffer, preferredEndianness: .little)
    }
}


extension ByteDecodable {
    /// Decode the type from `Data`.
    ///
    /// Initialize a new instance using the byte representation provided.
    ///
    /// - Note: Returns nil if no valid byte representation could be found.
    /// - Parameters:
    ///   - data: The data to decode.
    ///   - endianness: The preferred endianness to use for decoding if applicable.
    ///     This might not apply to certain data structures that operate on single byte level.
    public init?(data: Data, preferredEndianness endianness: Endianness = .little) {
        var buffer = ByteBuffer(data: data)
        self.init(from: &buffer, preferredEndianness: endianness)
    }
}


extension ByteEncodable {
    /// Encode to data.
    ///
    /// Encode the byte representation of this type.
    ///
    /// - Parameter endianness: The preferred endianness to use for encoding if applicable.
    ///     This might not apply to certain data structures that operate on single byte level.
    /// - Returns: The encoded data.
    public func encode(preferredEndianness endianness: Endianness = .little) -> Data {
        var buffer = ByteBuffer()
        encode(to: &buffer, preferredEndianness: endianness)
        return buffer.getData(at: 0, length: buffer.readableBytes) ?? Data()
    }
}
