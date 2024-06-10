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
    @available(*, deprecated, message: "Forward deprecation warning.")
    func testDeprecatedTypes() throws {
        // ensure that preferredEndianness is still forwarded to Primitive ByteCodable protocols and isn't just ignored

        let data = try XCTUnwrap(Data(hex: "0x0D05"))
        var buffer = ByteBuffer(data: data)

        let value = try XCTUnwrap(UInt16(data: data, preferredEndianness: .big))
        let value0 = try XCTUnwrap(UInt16(from: &buffer, preferredEndianness: .big))
        XCTAssertEqual(value, 3333)
        XCTAssertEqual(value0, 3333)

        buffer = ByteBuffer()

        let data0 = value.encode(preferredEndianness: .big)
        value0.encode(to: &buffer, preferredEndianness: .big)
        XCTAssertEqual(data0, data)
        XCTAssertEqual(buffer.getData(at: 0, length: buffer.readableBytes), data)
    }

    func testAmbiguousData() throws {
        // basically just a test if it compiles

        // PRIMITIVE BYTE CODABLE
        let data = try XCTUnwrap(Data(hex: "0x050D"))
        let value = UInt16(data: data)

        XCTAssertEqual(value, 3333)

        // BYTE CODABLE
        let stringData = try XCTUnwrap("Hello World".data(using: .utf8))
        let stringValue = try XCTUnwrap(String(data: stringData))
        XCTAssertEqual(stringValue, "Hello World")
    }

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
}
