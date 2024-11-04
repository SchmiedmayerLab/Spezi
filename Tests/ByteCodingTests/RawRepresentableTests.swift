//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) @testable import ByteCoding
import NIO
import XCTByteCoding
import XCTest


private enum SimpleEnum: UInt8, ByteCodable {
    case hello
    case world
}


private enum PrimitiveSimpleEnum: UInt16, PrimitiveByteCodable {
    case hello
    case world
}


final class RawRepresentableTests: XCTestCase {
    func testRawRepresentableByteCodable() throws {
        try testIdentity(from: SimpleEnum.hello)
        try testIdentity(from: SimpleEnum.world)

        // just test that overloads work and resolve
        let data = SimpleEnum.hello.encode()
        var buffer = ByteBuffer(data: data)
        _ = SimpleEnum(from: &buffer)
    }

    func testRawRepresentablePrimitiveByteCodable() throws {
        try testIdentity(from: PrimitiveSimpleEnum.hello)
        try testIdentity(from: PrimitiveSimpleEnum.world)

        // just test that overloads work and resolve
        let data = PrimitiveSimpleEnum.hello.encode()
        var buffer = ByteBuffer(data: data)
        _ = PrimitiveSimpleEnum(from: &buffer, endianness: .little)
        var buffer0 = ByteBuffer(data: data)
        _ = PrimitiveSimpleEnum(from: &buffer0)
    }
}
