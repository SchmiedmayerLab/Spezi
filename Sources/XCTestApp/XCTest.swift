//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// An error thrown in the XCT-based functions of the `XCTestExtensions` target.
public struct XCTestFailure: Error, CustomStringConvertible {
    let message: String
    let file: StaticString
    let line: Int
    
    
    public var description: String {
        "XCTestFailure in \(file) at line \(line)\(message.isEmpty ? "" : ": \(message)")"
    }
    
    
    /// An error thrown in the XCT-based functions of the `XCTestExtensions` target.
    /// - Parameters:
    ///   - message: An optional description of a failure.
    ///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
    ///   - line: The line number where the failure occurs. The default is the line number where you call this function.
    public init(message: String = "", file: StaticString = #file, line: Int = #line) {
        self.message = message
        self.file = file
        self.line = line
    }
}


/// Asserts that an expression is true.
///
/// This function generates a failure when `expression == false`.
/// - Parameters:
///   - condition: An expression of Boolean type.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
/// - Throws: This function throws an ``XCTestFailure`` failure when `expression == false`.
public func XCTAssert(_ condition: @autoclosure () -> Bool, message: String = "", file: StaticString = #file, line: Int = #line) throws {
    guard condition() else {
        throw XCTestFailure(message: message, file: file, line: line)
    }
}

/// Asserts that two values are equal.
///
/// Use this function to compare two non-optional values of the same type.
/// - Parameters:
///   - lhs: An expression of type `T`, where `T` is `Equatable`.
///   - rhs: A second expression of type `T`, where `T` is `Equatable`.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
/// - Throws: This function throws an ``XCTestFailure`` failure when `lhs` and `rhs` are not equal.
public func XCTAssertEqual<E: Equatable>(_ lhs: E, _ rhs: E, message: String = "", file: StaticString = #file, line: Int = #line) throws {
    guard lhs == rhs else {
        throw XCTestFailure(message: message, file: file, line: line)
    }
}


/// Asserts that an expression is nil.
///
/// This function generates a failure when `expression != nil`.
/// - Parameters:
///   - optional: An expression of type `Optional` to compare against nil.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
/// - Throws: This function throws an ``XCTestFailure`` failure when `expression != nil`.
public func XCTAssertNil<O>(_ optional: O?, message: String = "", file: StaticString = #file, line: Int = #line) throws {
    guard optional == nil else {
        throw XCTestFailure(message: message, file: file, line: line)
    }
}


/// Asserts that an expression is not `nil`, and returns the unwrapped value.
///
/// This function generates a failure when expression is `nil`. Otherwise, it returns the unwrapped value of expression for subsequent use in the test.
/// - Parameters:
///   - optional: An expression of type `T?`. The expression’s type determines the type of the return value.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call this function.
/// - Throws: This function throws an ``XCTestFailure`` failure when expression is not `nil`.
/// - Returns: The result of evaluating and unwrapping the expression, which is of type `T`. `XCTUnwrap()` only returns a value if expression is not `nil`.
public func XCTUnwrap<O>(_ optional: O?, message: String = "", file: StaticString = #file, line: Int = #line) throws -> O {
    guard let unwrapped = optional else {
        throw XCTestFailure(message: message, file: file, line: line)
    }
    return unwrapped
}
