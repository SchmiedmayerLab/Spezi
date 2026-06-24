//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// PDFKit is unavailable on watchOS; the PDF-backed attachment handling is gated out there.
#if canImport(PDFKit)
import PDFKit


// swiftlint:disable file_types_order
/// Protocol for creating PDFDocument objects - makes testing possible.
protocol PDFDocumentProviding {
    /// Creates a PDF document from raw data.
    /// - Parameter data: The PDF data to create a document from.
    /// - Returns: A PDFDocument if valid, nil otherwise.
    func createPDFDocument(from data: Data) -> PDFDocument?
}

/// Default implementation using the PDFDocument class from PDFKit.
struct DefaultPDFDocumentProvider: PDFDocumentProviding {
    func createPDFDocument(from data: Data) -> PDFDocument? {
        PDFDocument(data: data)
    }
}
#endif
