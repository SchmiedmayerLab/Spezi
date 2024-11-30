//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import ByteCoding
@testable import SpeziNumerics
import XCTByteCoding
import XCTest


final class MedFloatTests: XCTestCase { // swiftlint:disable:this type_body_length
    func testSpecialValues() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertTrue(MedFloat.nan.double.isNaN)
            XCTAssertTrue(MedFloat.nres.double.isNaN)
            XCTAssertTrue(MedFloat.reserved0.double.isNaN)
            XCTAssertEqual(MedFloat.infinity.double, .infinity)
            XCTAssertEqual(MedFloat.negativeInfinity.double, -Double.infinity)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testDoubleConversion() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertTrue(MedFloat(.nan).isNaN)
            XCTAssertTrue(MedFloat(.zero).isZero)
            XCTAssertEqual(MedFloat(.infinity), .infinity)
            XCTAssertEqual(MedFloat(-.infinity), .negativeInfinity)
            
            XCTAssertEqual(MedFloat(123000.0), MedFloat(exponent: 3, mantissa: 123))
            XCTAssertEqual(MedFloat(12.34), MedFloat(exponent: -2, mantissa: 1234))
            XCTAssertEqual(MedFloat(0.0000012), MedFloat(exponent: -7, mantissa: 12))
            
            XCTAssertEqual(MedFloat(1234.0), MedFloat(exponent: 0, mantissa: 1234))
            
            XCTAssertEqual(MedFloat(-123000.0), MedFloat(exponent: 3, mantissa: -123))
            XCTAssertEqual(MedFloat(-12.34), MedFloat(exponent: -2, mantissa: -1234))
            XCTAssertEqual(MedFloat(-0.0000012), MedFloat(exponent: -7, mantissa: -12))
            
            for value in [1.0, 12.34, 1.125] {
                XCTAssertEqual(MedFloat(value).double, value, accuracy: MedFloat.precision)
                XCTAssertEqual(SpeziNumerics.MedFloat16(value).double, value)
            }
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
        
        
        XCTAssertEqual(MedFloat32(52.471).double, 52.471, accuracy: MedFloat32.precision)
        XCTAssertNotEqual(MedFloat16(52.471).double, 52.471)
        XCTAssertEqual(MedFloat16(52.471).double, 52.5)
    }

    func testBasicRepresentations() { // swiftlint:disable:this function_body_length
        do { // MedFloat16
            let largeFloat = MedFloat16(exponent: 3, mantissa: 123)
            let smallFloat = MedFloat16(exponent: -2, mantissa: 1234)
            let smallSmallFloat = MedFloat16(exponent: -7, mantissa: 12)
            
            let zeroExponentFloat = MedFloat16(exponent: 0, mantissa: 1234)
            
            let negLargeFloat = MedFloat16(exponent: 3, mantissa: -123)
            let negSmallFloat = MedFloat16(exponent: -2, mantissa: -1234)
            let negSmallSmallFloat = MedFloat16(exponent: -7, mantissa: -12)
            
            XCTAssertEqual(largeFloat.exponent, 2)
            XCTAssertEqual(largeFloat.mantissa, 1230)
            XCTAssertEqual(smallFloat.exponent, -2)
            XCTAssertEqual(smallFloat.mantissa, 1234)
            XCTAssertEqual(smallSmallFloat.exponent, -8)
            XCTAssertEqual(smallSmallFloat.mantissa, 120)
            
            XCTAssertEqual(zeroExponentFloat.exponent, 0)
            XCTAssertEqual(zeroExponentFloat.mantissa, 1234)
            
            XCTAssertEqual(negLargeFloat.exponent, 2)
            XCTAssertEqual(negLargeFloat.mantissa, -1230)
            XCTAssertEqual(negSmallFloat.exponent, -2)
            XCTAssertEqual(negSmallFloat.mantissa, -1234)
            XCTAssertEqual(negSmallSmallFloat.exponent, -8)
            XCTAssertEqual(negSmallSmallFloat.mantissa, -120)
            
            XCTAssertTrue(largeFloat.isFinite)
            XCTAssertTrue(smallFloat.isFinite)
            XCTAssertTrue(smallSmallFloat.isFinite)
            XCTAssertTrue(negLargeFloat.isFinite)
            XCTAssertTrue(negSmallFloat.isFinite)
            XCTAssertTrue(negSmallSmallFloat.isFinite)
            
            XCTAssertEqual(largeFloat.double, 123000.0)
            XCTAssertEqual(smallFloat.double, 12.34)
            XCTAssertEqual(smallSmallFloat.double, 0.0000012)
            XCTAssertEqual(zeroExponentFloat.double, 1234.0)
            XCTAssertEqual(negLargeFloat.double, -123000.0)
            XCTAssertEqual(negSmallFloat.double, -12.34)
            XCTAssertEqual(negSmallSmallFloat.double, -0.0000012)
            
            
            XCTAssertEqual(MedFloat16.nan.description, "nan")
            XCTAssertEqual(MedFloat16.reserved0.description, "nan")
            XCTAssertEqual(MedFloat16.nres.description, "nres")
            XCTAssertEqual(MedFloat16.zero.description, "0.0")
            XCTAssertEqual(MedFloat16.infinity.description, "inf")
            XCTAssertEqual(MedFloat16.negativeInfinity.description, "-inf")
            
            XCTAssertEqual(largeFloat.description, "123000.0")
            XCTAssertEqual(smallFloat.description, "12.34")
            XCTAssertEqual(smallSmallFloat.description, "0.0000012")
            XCTAssertEqual(zeroExponentFloat.description, "1234.0")
            XCTAssertEqual(negLargeFloat.description, "-123000.0")
            XCTAssertEqual(negSmallFloat.description, "-12.34")
            XCTAssertEqual(negSmallSmallFloat.description, "-0.0000012")
            
            XCTAssertEqual(MedFloat16(127).description, "127.0")
            XCTAssertEqual(MedFloat16(12).description, "12.0")
        }
        
        
        do { // MedFloat32
            let largeFloat = MedFloat32(exponent: 3, mantissa: 123)
            let smallFloat = MedFloat32(exponent: -2, mantissa: 1234)
            let smallSmallFloat = MedFloat32(exponent: -7, mantissa: 12)
            
            let zeroExponentFloat = MedFloat32(exponent: 0, mantissa: 1234)
            
            let negLargeFloat = MedFloat32(exponent: 3, mantissa: -123)
            let negSmallFloat = MedFloat32(exponent: -2, mantissa: -1234)
            let negSmallSmallFloat = MedFloat32(exponent: -7, mantissa: -12)
            
            XCTAssertEqual(largeFloat.exponent, -1)
            XCTAssertEqual(largeFloat.mantissa, 1230000)
            XCTAssertEqual(smallFloat.exponent, -5)
            XCTAssertEqual(smallFloat.mantissa, 1234000)
            XCTAssertEqual(smallSmallFloat.exponent, -12)
            XCTAssertEqual(smallSmallFloat.mantissa, 1200000)
            
            XCTAssertEqual(zeroExponentFloat.exponent, -3)
            XCTAssertEqual(zeroExponentFloat.mantissa, 1234000)
            
            XCTAssertEqual(negLargeFloat.exponent, -1)
            XCTAssertEqual(negLargeFloat.mantissa, -1230000)
            XCTAssertEqual(negSmallFloat.exponent, -5)
            XCTAssertEqual(negSmallFloat.mantissa, -1234000)
            XCTAssertEqual(negSmallSmallFloat.exponent, -12)
            XCTAssertEqual(negSmallSmallFloat.mantissa, -1200000)
            
            XCTAssertTrue(largeFloat.isFinite)
            XCTAssertTrue(smallFloat.isFinite)
            XCTAssertTrue(smallSmallFloat.isFinite)
            XCTAssertTrue(negLargeFloat.isFinite)
            XCTAssertTrue(negSmallFloat.isFinite)
            XCTAssertTrue(negSmallSmallFloat.isFinite)
            
            XCTAssertEqual(largeFloat.double, 123000.0)
            XCTAssertEqual(smallFloat.double, 12.34, accuracy: MedFloat32.precision)
            XCTAssertEqual(smallSmallFloat.double, 0.0000012)
            XCTAssertEqual(zeroExponentFloat.double, 1234.0)
            XCTAssertEqual(negLargeFloat.double, -123000.0)
            XCTAssertEqual(negSmallFloat.double, -12.34, accuracy: MedFloat32.precision)
            XCTAssertEqual(negSmallSmallFloat.double, -0.0000012)
            
            
            XCTAssertEqual(MedFloat32.nan.description, "nan")
            XCTAssertEqual(MedFloat32.reserved0.description, "nan")
            XCTAssertEqual(MedFloat32.nres.description, "nres")
            XCTAssertEqual(MedFloat32.zero.description, "0.0")
            XCTAssertEqual(MedFloat32.infinity.description, "inf")
            XCTAssertEqual(MedFloat32.negativeInfinity.description, "-inf")
            
            XCTAssertEqual(largeFloat.description, "123000.0")
            XCTAssertEqual(smallFloat.description, "12.34")
            XCTAssertEqual(smallSmallFloat.description, "0.0000012")
            XCTAssertEqual(zeroExponentFloat.description, "1234.0")
            XCTAssertEqual(negLargeFloat.description, "-123000.0")
            XCTAssertEqual(negSmallFloat.description, "-12.34")
            XCTAssertEqual(negSmallSmallFloat.description, "-0.0000012")
            
            XCTAssertEqual(MedFloat32(127).description, "127.0")
            XCTAssertEqual(MedFloat32(12).description, "12.0")
        }
        
        
        XCTAssertEqual(MedFloat16(exponent: 45, mantissa: 23), .infinity)
        XCTAssertEqual(MedFloat16(exponent: 2, mantissa: 23000), .infinity)
        XCTAssertEqual(MedFloat16(exponent: 2, mantissa: -23000), .negativeInfinity)
        XCTAssertEqual(MedFloat16(exponent: -2, mantissa: 6500), .infinity)
        XCTAssertEqual(MedFloat16(exponent: -9, mantissa: 650), .infinity)
        XCTAssertEqual(MedFloat16(exponent: -2, mantissa: -6500), .negativeInfinity)
        XCTAssertEqual(MedFloat16(exponent: -9, mantissa: -650), .negativeInfinity)
        
        let largeDoubleVal: Double = 23000000000000000000000000000000000000000000000.0
        XCTAssertEqual(MedFloat32(exponent: 45, mantissa: 23).double, largeDoubleVal)
        XCTAssertEqual(MedFloat32(largeDoubleVal).double, largeDoubleVal)
        XCTAssertEqual(MedFloat32(exponent: 2, mantissa: 23000), 2300000)
        XCTAssertEqual(MedFloat32(exponent: 2, mantissa: -23000), -2300000)
        XCTAssertEqual(MedFloat32(exponent: -2, mantissa: 6500), 65.0)
        XCTAssertEqual(MedFloat32(exponent: -9, mantissa: 650), 0.00000065)
        XCTAssertEqual(MedFloat32(exponent: -2, mantissa: -6500), -65)
        XCTAssertEqual(MedFloat32(exponent: -9, mantissa: -650), -0.00000065)
        
        XCTAssertEqual(MedFloat32(exponent: 127, mantissa: 500000000), .infinity)
        XCTAssertEqual(MedFloat32(exponent: 2, mantissa: 500000000), .infinity)
        XCTAssertEqual(MedFloat32(exponent: 2, mantissa: -500000000), .negativeInfinity)
        XCTAssertEqual(MedFloat32(exponent: -2, mantissa: 65000000), .infinity)
        XCTAssertEqual(MedFloat32(exponent: -9, mantissa: 65000000), .infinity)
        XCTAssertEqual(MedFloat32(exponent: -2, mantissa: -65000000), .negativeInfinity)
        XCTAssertEqual(MedFloat32(exponent: -9, mantissa: -65000000), .negativeInfinity)
    }


    func testHashable() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            var values: Set<MedFloat> = []
            
            XCTAssertTrue(values.insert(.nan).inserted)
            XCTAssertTrue(values.insert(.nan).inserted)
            XCTAssertTrue(values.insert(.zero).inserted)
            XCTAssertFalse(values.insert(MedFloat(exponent: -2, mantissa: 0)).inserted)
            XCTAssertTrue(values.insert(2).inserted)
            XCTAssertTrue(values.insert(4).inserted)
            XCTAssertFalse(values.insert(4).inserted)
            XCTAssertTrue(values.insert(.nres).inserted)
            XCTAssertTrue(values.insert(.nres).inserted)
            XCTAssertTrue(values.insert(.reserved0).inserted)
            XCTAssertTrue(values.insert(.reserved0).inserted)
            
            XCTAssertEqual(MedFloat.nan.hashValue, MedFloat.nan.hashValue)
            XCTAssertEqual(MedFloat.nres.hashValue, MedFloat.nres.hashValue)
            XCTAssertEqual(MedFloat.reserved0.hashValue, MedFloat.reserved0.hashValue)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testEquality() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertNotEqual(MedFloat.nan, .nan)
            XCTAssertNotEqual(MedFloat.nan, .nres)
            XCTAssertNotEqual(MedFloat.nan, .infinity)
            XCTAssertNotEqual(MedFloat.nan, MedFloat(123))
            XCTAssertNotEqual(MedFloat.nres, .nres)
            
            
            let float0 = MedFloat(exponent: -1, mantissa: 130)
            let float1 = MedFloat(exponent: 0, mantissa: 13)
            let float2 = MedFloat(exponent: -2, mantissa: 1300)
            
            XCTAssertEqual(float0, float1)
            XCTAssertEqual(float0, float2)
            XCTAssertEqual(float1, float2)
            XCTAssertEqual(float0.description, float1.description)
            XCTAssertEqual(float1.description, float2.description)
            
            let float3 = MedFloat(exponent: 1, mantissa: 10)
            let float4 = MedFloat(exponent: 0, mantissa: 100)
            
            XCTAssertEqual(float3, float4)
            XCTAssertEqual(MedFloat.zero, MedFloat(exponent: 3, mantissa: 0))
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testComparable() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertFalse(MedFloat.nan < .nan)
            XCTAssertFalse(MedFloat.nan < .nan)
            XCTAssertFalse(MedFloat.nan < .nres)
            XCTAssertFalse(MedFloat.nan < .reserved0)
            XCTAssertFalse(MedFloat.nres < .nres)
            XCTAssertFalse(MedFloat.nres < .nan)
            XCTAssertFalse(MedFloat.nres < .reserved0)
            XCTAssertFalse(MedFloat.reserved0 < .reserved0)
            XCTAssertFalse(MedFloat.reserved0 < .nan)
            XCTAssertFalse(MedFloat.reserved0 < .nres)
            
            XCTAssertFalse(MedFloat.negativeInfinity < .negativeInfinity)
            XCTAssertFalse(MedFloat.negativeInfinity < .nan)
            XCTAssertFalse(-503 < MedFloat.negativeInfinity)
            XCTAssertFalse(.nan < MedFloat.negativeInfinity)
            XCTAssertLessThan(MedFloat.negativeInfinity, -503)
            XCTAssertLessThan(MedFloat.negativeInfinity, .infinity)
            
            XCTAssertFalse(MedFloat.infinity < 1234012)
            XCTAssertFalse(MedFloat.infinity < .nan)
            XCTAssertFalse(MedFloat.infinity < .infinity)
            XCTAssertFalse(.nan < MedFloat.infinity)
            XCTAssertLessThan(123123, .infinity)
            
            XCTAssertFalse(MedFloat.zero < MedFloat(exponent: 3, mantissa: 0))
            XCTAssertLessThan(MedFloat(-3), 0)
            XCTAssertLessThan(MedFloat(-3), 4)
            XCTAssertLessThan(MedFloat.zero, 4)
            XCTAssertLessThan(MedFloat(0.578), 4)
            XCTAssertLessThan(MedFloat(0.578), 4)
            XCTAssertLessThan(MedFloat(-0.578), 4)
            
            XCTAssertLessThan(MedFloat(-7.58), -0.78)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testLiteralInits() {
        XCTAssertEqual(MedFloat16(150000000000), .infinity)
        XCTAssertEqual(MedFloat16(-150000000000), .negativeInfinity)
        print(Float(sign: .plus, exponent: 267, significand: 0.6))
        print(MedFloat16(150000000000).description)
        print(MedFloat16(150000000000).debugDescription)
    }

    
    func testExactlyConversion() {
        XCTAssertNil(MedFloat16(exactly: Int16.max))
        XCTAssertNil(MedFloat16(exactly: UInt16.max))
        XCTAssertNotNil(MedFloat32(exactly: Int16.max))
        XCTAssertNotNil(MedFloat32(exactly: UInt16.max))
        
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertEqual(MedFloat(exactly: UInt8.max), 255)
            XCTAssertEqual(MedFloat(exactly: Int8.max), 127)
            XCTAssertEqual(MedFloat(exactly: 12400), 12400)
            
            XCTAssertNil(MedFloat(exactly: Int32.max))
            XCTAssertNil(MedFloat(exactly: UInt32.max))
            XCTAssertNil(MedFloat(exactly: Int64.max))
            XCTAssertNil(MedFloat(exactly: UInt64.max))
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testAddition() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertTrue((MedFloat.infinity + .negativeInfinity).isNaN)
            XCTAssertTrue((MedFloat.negativeInfinity + .infinity).isNaN)
            
            XCTAssertTrue((MedFloat.nan + .nan).isNaN)
            XCTAssertTrue((MedFloat.nres + .nres).isNaN)
            XCTAssertTrue((MedFloat.nan + .nres).isNaN)
            XCTAssertTrue((MedFloat.nres + .nan).isNaN)
            XCTAssertTrue((MedFloat.reserved0 + .nan).isNaN)
            XCTAssertTrue((MedFloat.nan + .reserved0).isNaN)
            XCTAssertTrue((MedFloat.nres + .reserved0).isNaN)
            XCTAssertTrue((MedFloat.reserved0 + .nres).isNaN)
            
            XCTAssertEqual(MedFloat.infinity + .infinity, .infinity)
            XCTAssertEqual(MedFloat.infinity + 12, .infinity)
            XCTAssertEqual(MedFloat.infinity + -12, .infinity)
            
            XCTAssertEqual(MedFloat.negativeInfinity + .negativeInfinity, .negativeInfinity)
            XCTAssertEqual(MedFloat.negativeInfinity + 12, .negativeInfinity)
            XCTAssertEqual(MedFloat.negativeInfinity + -12, .negativeInfinity)
            
            
            XCTAssertEqual(MedFloat(15) + 12, 27)
            XCTAssertEqual(MedFloat(1500000000) + 1200000000, 2700000000)
            XCTAssertEqual(MedFloat(15000000) + 120000, 15120000)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
        
        XCTAssertEqual(MedFloat16(15000000000) + 12000000000, .infinity)
        XCTAssertEqual(MedFloat32(15000000000) + 12000000000, 27000000000)
        
        XCTAssertNotEqual(MedFloat32(MedFloat32.maxDoubleValue), .infinity)
        XCTAssertEqual(MedFloat32(MedFloat32.maxDoubleValue.nextUp), .infinity)
        let step = MedFloat32.maxDoubleValue.nextUp - MedFloat32.maxDoubleValue
        XCTAssertEqual((MedFloat32(MedFloat32.maxDoubleValue) + MedFloat32(step)).double, .infinity)
    }

    func testNegate() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertEqual(-MedFloat.negativeInfinity, .infinity)
            XCTAssertEqual(-MedFloat.infinity, .negativeInfinity)
            XCTAssertTrue((-MedFloat.nan).isNaN)
            XCTAssertTrue((-MedFloat.nres).isNRes)
            XCTAssertEqual(MedFloat(4), 4)
            XCTAssertEqual(MedFloat(-4), -4)
            XCTAssertEqual(MedFloat(-4.128), -4.128)
            XCTAssertEqual(-MedFloat(4), -4)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testMultiply() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            var value: MedFloat = 2
            
            value *= 10
            XCTAssertEqual(value, 20)
            
            value *= (0.25 as MedFloat)
            XCTAssertEqual(value, 5)
        }
    }

    func testMagnitude() {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) {
            XCTAssertTrue(MedFloat.nan.magnitude.isNaN)
            XCTAssertTrue(MedFloat.nres.magnitude.isNRes)
            XCTAssertTrue(MedFloat.reserved0.magnitude.isReserved0)
            
            XCTAssertEqual(MedFloat.infinity.magnitude, .infinity)
            XCTAssertEqual(MedFloat.negativeInfinity.magnitude, .infinity)
            
            XCTAssertEqual(MedFloat.zero.magnitude, .zero)
            
            XCTAssertEqual(MedFloat(12.5).magnitude, 12.5)
            XCTAssertEqual(MedFloat(-12.5).magnitude, 12.5)
        }
        imp(MedFloat16.self)
        imp(MedFloat32.self)
    }

    func testByteCoding() throws {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) throws {
            try testIdentity(from: MedFloat.infinity)
            try testIdentity(from: MedFloat.negativeInfinity)
            try testIdentity(from: MedFloat.zero)
            try testIdentity(from: MedFloat(12.5))
            try testIdentity(from: MedFloat(-12.5))
        }
        try imp(MedFloat16.self)
        try imp(MedFloat32.self)
        
        // nan-like values don't compare, therefore we check for byte-wise equality
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x07FF")))
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x0800")))
        try testIdentity(of: MedFloat16.self, from: XCTUnwrap(Data(hex: "0x0801")))
        try testIdentity(of: MedFloat32.self, from: XCTUnwrap(Data(hex: "0x007FFFFF")))
        try testIdentity(of: MedFloat32.self, from: XCTUnwrap(Data(hex: "0x00800000")))
        try testIdentity(of: MedFloat32.self, from: XCTUnwrap(Data(hex: "0x00800001")))
    }

    func testCodable() throws {
        func imp<MedFloat: MedFloatProtocol>(_: MedFloat.Type) throws {
            func testCodableReturningResult<T: Codable & Equatable>(from value: T) throws -> T {
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                
                let data = try encoder.encode(value)
                return try decoder.decode(T.self, from: data)
            }
            func testCodable<T: Codable & Equatable>(from value: T) throws {
                let result = try testCodableReturningResult(from: value)
                XCTAssertEqual(result, value)
            }
            
            try testCodable(from: MedFloat.infinity)
            try testCodable(from: MedFloat.negativeInfinity)
            try testCodable(from: MedFloat.zero)
            try testCodable(from: MedFloat(12.5))
            try testCodable(from: MedFloat(-12.5))
            
            // nan-like values don't compare, therefore we check for byte-wise equality
            XCTAssertEqual(try testCodableReturningResult(from: MedFloat.nan).bitPattern, MedFloat.nan.bitPattern)
            XCTAssertEqual(try testCodableReturningResult(from: MedFloat.nres).bitPattern, MedFloat.nres.bitPattern)
            XCTAssertEqual(try testCodableReturningResult(from: MedFloat.reserved0).bitPattern, MedFloat.reserved0.bitPattern)
        }
        try imp(MedFloat16.self)
        try imp(MedFloat32.self)
    }
}
