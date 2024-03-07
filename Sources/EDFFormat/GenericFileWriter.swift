//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import ByteCoding
import Foundation
import NIO
import NIOFoundationCompat


/// A EDF file writer.
///
/// A file writer for a ``EDFSample``.
///
/// Below is a short code example on how to use the file writer class.
///
/// ```swift
/// let url = URL(filePath: "/your/file/path.edf") // make sure the file exists
///
/// let file: FileInformation = // ...
/// let signals: [Signal] = [
///     // define your signal descriptions ...
/// ]
///
/// let writer = try EDFFileWriter(url: url, information: file, signals: signals)
///
/// // make sure to write the file header once ...
/// try writer.writeHeader()
///
/// // continuously add your data records ...
/// let record = DataRecord(channels: [
///     // add your `Channel` data with `EDFSample`s
/// ])
/// try writer.addRecord(record)
///
/// // ...
///
/// // close file once finished
/// try writer.close()
/// ```
public typealias EDFFileWriter = GenericFileWriter<EDFSample>


/// A BDF file writer.
///
/// A file writer for a ``BDFSample``.
///
/// Below is a short code example on how to use the file writer class.
///
/// ```swift
/// let url = URL(filePath: "/your/file/path.bdf") // make sure the file exists
///
/// let file: FileInformation = // ...
/// let signals: [Signal] = [
///     // define your signal descriptions ...
/// ]
///
/// let writer = try BDFFileWriter(url: url, information: file, signals: signals)
///
/// // make sure to write the file header once ...
/// try writer.writeHeader()
///
/// // continuously add your data records ...
/// let record = DataRecord(channels: [
///     // add your `Channel` data with `EDFSample`s
/// ])
/// try writer.addRecord(record)
///
/// // ...
///
/// // close file once finished
/// try writer.close()
/// ```
public typealias BDFFileWriter = GenericFileWriter<BDFSample>


/// A EDF/BDF file writer for a given `Sample` type.
///
/// A file writer for a generic ``Sample`` type.
///
/// - Tip: Use the ``EDFFileWriter`` or ``BDFFileWriter`` typealias for the respective sample types
///     to generate EDF/EDF+ or BDF/BDF+ files.
///
/// Below is a short code example on how to use the file writer class.
///
/// ```swift
/// let url = URL(filePath: "/your/file/path.edf") // make sure the file exists
///
/// let file: FileInformation = // ...
/// let signals: [Signal] = [
///     // define your signal descriptions ...
/// ]
///
/// let writer = try GenericFileWriter<EDFSample>(url: url, information: file, signals: signals)
///
/// // make sure to write the file header once ...
/// try writer.writeHeader()
///
/// // continuously add your data records ...
/// let record = DataRecord(channels: [
///     // add your `Channel` data
/// ])
/// try writer.addRecord(record)
///
/// // ...
///
/// // close file once finished
/// try writer.close()
/// ```
public final class GenericFileWriter<S: Sample> {
    private static var dataRecordsCountOffset: UInt64 {
        8 + 80 + 80 + 8 + 8 + 8 + 44
    }

    /// The file format.
    public let format: FileFormat
    /// File information
    public let fileInformation: FileInformation
    /// The format of the file records.
    private let dataFormat: FileRecordsFormat
    /// Array of signal descriptions.
    public let signals: [Signal]

    private let fileHandle: FileHandle
    private let lock = NSLock()
    private var dataRecordsCount: Int = -1
    private var writerIndex: UInt64 = 0
    private var didClose = false


    /// The channel count this file contains.
    public var channelCount: Int {
        signals.count
    }

    private var headerLength: Int {
        256 * (1 + channelCount)
    }

    private init(url: URL, format: FileFormat, fileInformation: FileInformation, dataFormat: FileRecordsFormat, signals: [Signal]) throws {
        self.format = format
        self.fileInformation = fileInformation
        self.dataFormat = dataFormat
        self.signals = signals

        self.fileHandle = try FileHandle(forWritingTo: url)

        try verifyAsciiInput(channelCount, maxLength: 4, for: "channelCount")
        try verifyAsciiInput(headerLength, maxLength: 8, for: "headerLength")

        try fileInformation.verifyAsciiInputs()
        for signal in signals {
            try signal.verifyAsciiInputs()
        }
    }


    /// Write the file header to disk.
    /// - Throws: Throws if file access fails.
    public func writeHeader() throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        self.writerIndex = 0
        try fileHandle.seek(toOffset: writerIndex) // make sure we are at the start

        var header = ByteBuffer()
        header.reserveCapacity(headerLength)
        self.encodeHeader(to: &header)


        let headerData = header.getData(at: 0, length: header.readableBytes) ?? .init()
        try fileHandle.write(contentsOf: headerData)

        writerIndex += UInt64(headerData.count)
    }

    /// Append new data record to the file.
    /// - Parameter record: The set of sample data grouped by their channel.
    /// - Throws: Throws if file access fails or invalid data record was provided (e.g., invalid channel count or sample count).
    public func addRecord(_ record: DataRecord<S>) throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        if writerIndex == 0 {
            throw EDFEncodingError.headerNotWritten
        }

        try fileHandle.seek(toOffset: writerIndex)

        if record.channels.count != channelCount { // == signals.count
            throw EDFEncodingError.invalidChannelCount(expected: channelCount, received: record.channels.count)
        }

        var totalSampleCount = 0 // count to reserve capacity later on
        for index in signals.indices {
            let signal = signals[index]
            let channel = record.channels[index]

            if channel.samples.count != signal.sampleCount {
                throw EDFEncodingError.invalidSampleCount(channel: signal.label, expected: signal.sampleCount, received: channel.samples.count)
            }
            totalSampleCount += signal.sampleCount
        }

        var recordBuffer = ByteBuffer()
        switch format {
        case .edf:
            recordBuffer.reserveCapacity(16 * totalSampleCount)
        case .bdf:
            recordBuffer.reserveCapacity(24 * totalSampleCount)
        }
        record.encode(to: &recordBuffer, preferredEndianness: .little)

        let recordData = recordBuffer.getData(at: 0, length: recordBuffer.readableBytes) ?? .init()
        try fileHandle.write(contentsOf: recordData)

        writerIndex += UInt64(recordData.count)

        if self.dataRecordsCount < 0 {
            self.dataRecordsCount = 0
        }
        self.dataRecordsCount += 1
        
        try verifyAsciiInput(dataRecordsCount, maxLength: 8, for: "dataRecordsCount")

        try updateRecordsCount()
    }

    private func updateRecordsCount() throws {
        // update the dataRecordsCount
        try fileHandle.seek(toOffset: Self.dataRecordsCountOffset)

        var countBuffer = ByteBuffer()
        countBuffer.reserveCapacity(8)
        countBuffer.writeEDFAscii(dataRecordsCount, length: 8)

        let countData = countBuffer.getData(at: 0, length: countBuffer.readableBytes) ?? .init()
        try fileHandle.write(contentsOf: countData)
    }

    /// Finish writing file by closing the file handle.
    /// - Throws: Throws if file interaction fails.
    public func close() throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        if didClose {
            return
        }

        if dataRecordsCount < 0 {
            // no records got written. so set to zero
            dataRecordsCount = 0
            try updateRecordsCount()
        }

        try fileHandle.close()
        didClose = true
    }

    deinit {
        try? close()
    }
}


extension GenericFileWriter: @unchecked Sendable {}


extension GenericFileWriter {
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }

    private static var yyDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM."
        return formatter
    }

    private static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH.mm.ss"
        return formatter
    }

    func encodeHeader(to byteBuffer: inout ByteBuffer) {
        format.encode(to: &byteBuffer, preferredEndianness: .little)

        fileInformation.subject.encode(to: &byteBuffer, preferredEndianness: .little)
        fileInformation.recording.encode(to: &byteBuffer, preferredEndianness: .little)

        let year = Calendar.current.component(.year, from: fileInformation.recording.startDate)
        if year >= 1985 && year <= 2084 {
            byteBuffer.writeEDFAscii(Self.dateFormatter.string(from: fileInformation.recording.startDate), length: 8)
        } else {
            // The 'startdate' and 'starttime' fields in the header should contain only characters 0-9, and the period (.)
            // as a separator, for example "02.08.51". In the 'startdate', use 1985 as a clipping date in order to avoid the Y2K problem.
            // So, the years 1985-1999 must be represented by yy=85-99 and the years 2000-2084 by yy=00-84. After 2084, yy must be 'yy'
            // and only item 4 of this paragraph defines the date (in the recording info field).
            byteBuffer.writeEDFAscii(Self.yyDateFormatter.string(from: fileInformation.recording.startDate) + "yy", length: 8)
        }

        byteBuffer.writeEDFAscii(Self.timeFormatter.string(from: fileInformation.recording.startDate), length: 8)

        byteBuffer.writeEDFAscii(headerLength, length: 8)
        dataFormat.encode(to: &byteBuffer, preferredEndianness: .little)

        byteBuffer.writeEDFAscii(dataRecordsCount, length: 8)
        byteBuffer.writeEDFAscii(fileInformation.recordDuration, length: 8)

        byteBuffer.writeEDFAscii(channelCount, length: 4)
        signals.encode(to: &byteBuffer, preferredEndianness: .little)
    }
}


extension GenericFileWriter where S == EDFSample {
    /// Create a new EDF file writer.
    /// - Parameters:
    ///   - url: The url to the file to write. Note that the file must be created already.
    ///   - format: The data records format.
    ///   - information: The file information.
    ///   - signals: The array of signal descriptions.
    /// - Throws: Throws if FileHandle creation fails.
    public convenience init(url: URL, format: EDFRecordsFormat = .custom(), information: FileInformation, signals: [Signal]) throws {
        // swiftlint:disable:previous function_default_parameter_at_end
        try self.init(url: url, format: .edf, fileInformation: information, dataFormat: .init(from: format), signals: signals)
    }
}


extension GenericFileWriter where S == BDFSample {
    /// Create a new BDF file writer.
    /// - Parameters:
    ///   - url:  The url to the file to write. Note that the file must be created already.
    ///   - format: The file format.
    ///   - information: The file information.
    ///   - signals: The array of signal descriptions.
    /// - Throws: Throws if FileHandle creation fails.
    public convenience init(url: URL, format: FileFormat = .bdf, information: FileInformation, signals: [Signal]) throws {
        // swiftlint:disable:previous function_default_parameter_at_end

        let dataFormat: FileRecordsFormat
        switch format {
        case .edf:
            dataFormat = .biosemi
        case .bdf:
            dataFormat = .bits24
        }

        try self.init(url: url, format: format, fileInformation: information, dataFormat: dataFormat, signals: signals)
    }
}
