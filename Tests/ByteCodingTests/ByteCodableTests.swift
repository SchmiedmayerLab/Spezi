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


final class ByteCodableTests: XCTestCase {
    func testData() throws {
        let data = try XCTUnwrap(Data(hex: "0xAABBCCDDEE"))

        try testIdentity(of: Data.self, from: data)

        let data0 = Data(data: data)
        XCTAssertEqual(data0, data)
    }

    func testBoolean() throws {
        let trueData = try XCTUnwrap(Data(hex: "0x01"))
        try testIdentity(of: Bool.self, from: trueData)

        let falseData = try XCTUnwrap(Data(hex: "0x00"))
        try testIdentity(of: Bool.self, from: falseData)

        var empty = ByteBuffer()
        XCTAssertNil(Bool(from: &empty))
    }

    func testString() throws {
        let data = try XCTUnwrap("Hello World".data(using: .utf8))
        try testIdentity(of: String.self, from: data)

        var empty = ByteBuffer()
        XCTAssertEqual(String(from: &empty), "")
    }

    func testInt8() throws {
        try testIdentity(from: Int8.max)
        try testIdentity(from: Int8.min)
    }

    func testInt16() throws {
        try testIdentity(from: Int16.max)
        try testIdentity(from: Int16.min)
    }

    func testInt32() throws {
        try testIdentity(from: Int32.max)
        try testIdentity(from: Int32.min)
    }

    func testInt64() throws {
        try testIdentity(from: Int64.max)
        try testIdentity(from: Int64.min)
    }

    func testUInt8() throws {
        try testIdentity(from: UInt8.max)
        try testIdentity(from: UInt8.min)

        var empty = ByteBuffer()
        XCTAssertNil(UInt8(from: &empty))
    }

    func testUInt16() throws {
        try testIdentity(from: UInt16.max)
        try testIdentity(from: UInt16.min)
    }

    func testUInt32() throws {
        try testIdentity(from: UInt32.max)
        try testIdentity(from: UInt32.min)
    }

    func testUInt64() throws {
        try testIdentity(from: UInt64.max)
        try testIdentity(from: UInt64.min)
    }

    func testFloat32() throws {
        try testIdentity(from: Float32.pi)
        try testIdentity(from: Float32.infinity)
        try testIdentity(from: Float32(17.2783912))
    }

    func testFloat64() throws {
        try testIdentity(from: Float64.pi)
        try testIdentity(from: Float64.infinity)
        try testIdentity(from: Float64(23712.2123123))
    }

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
