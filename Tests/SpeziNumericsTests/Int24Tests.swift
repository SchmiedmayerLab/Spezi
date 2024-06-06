//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) @testable import ByteCoding
import NIO
@testable import SpeziNumerics
import XCTByteCoding
import XCTest


final class Int24Tests: XCTestCase {
    func testReadInt24Big() throws {
        let data = try XCTUnwrap(Data(hex: "0xFF0000"))
        var buffer = ByteBuffer(data: data)

        let uint = try XCTUnwrap(buffer.getUInt24(at: 0, endianness: .big))
        let int = try XCTUnwrap(buffer.readInt24(endianness: .big))

        XCTAssertEqual(uint, 0xFF0000)
        XCTAssertEqual(int, -65536)
    }

    func testReadInt24Little() throws {
        let data = try XCTUnwrap(Data(hex: "0x0000FF"))
        var buffer = ByteBuffer(data: data)

        let uint = try XCTUnwrap(buffer.readUInt24(endianness: .little))
        buffer.moveReaderIndex(to: 0)
        let int = try XCTUnwrap(buffer.readInt24(endianness: .little))

        XCTAssertEqual(uint, 0xFF0000)
        XCTAssertEqual(int, -65536)
    }

    func testReadInt24Reading() throws {
        let data = try XCTUnwrap(Data(hex: "0x6fffff"))
        let buffer = ByteBuffer(data: data)

        let intBE = try XCTUnwrap(buffer.getInt24(at: 0, endianness: .big))
        let intLE = try XCTUnwrap(buffer.getInt24(at: 0, endianness: .little))

        XCTAssertEqual(intBE, 7340031)
        XCTAssertEqual(intLE, -145)
    }

    func testInt24WriteLE() {
        var buffer = ByteBuffer()

        buffer.writeInt24(-65536, endianness: .little)
        buffer.writeInt24(-8_388_608, endianness: .little)
        buffer.writeInt24(7340031, endianness: .little)

        let data = buffer.getData(at: 0, length: buffer.readableBytes)
        XCTAssertEqual(data?.hexString().uppercased(), "0000FF" + "000080" + "FFFF6F")
    }

    func testInt24WriteBE() throws {
        var buffer = ByteBuffer()

        buffer.writeInt24(-65536, endianness: .big)
        buffer.writeInt24(-8_388_608, endianness: .big)
        buffer.writeInt24(7340031, endianness: .big)

        let data = try XCTUnwrap(buffer.getData(at: 0, length: buffer.readableBytes))
        XCTAssertEqual(data.hexString().uppercased(), "FF0000" + "800000" + "6FFFFF")
    }

    func testUint24Write() throws {
        var buffer = ByteBuffer()

        buffer.writeUInt24(256, endianness: .big)
        buffer.writeUInt24(512, endianness: .little)

        let data = try XCTUnwrap(buffer.getData(at: 0, length: buffer.readableBytes))
        XCTAssertEqual(data.hexString().uppercased(), "000100" + "000200")
    }
}
