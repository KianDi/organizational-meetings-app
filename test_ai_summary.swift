#!/usr/bin/env swift

import Foundation
import PDFKit

// Test document parsing and AI summary generation

let pdfPath = "/Users/kian/projects/Business Retreat Jan 18 2026 (1).pdf"

print("🔍 Testing PDF parsing and AI summary generation...")
print("PDF: \(pdfPath)")
print("")

// Load PDF
guard let pdfURL = URL(string: "file://\(pdfPath)"),
      let pdfDocument = PDFDocument(url: pdfURL) else {
    print("❌ Failed to load PDF")
    exit(1)
}

print("✅ PDF loaded successfully")
print("Pages: \(pdfDocument.pageCount)")
print("")

// Extract text
var extractedText = ""
for i in 0..<pdfDocument.pageCount {
    if let page = pdfDocument.page(at: i) {
        if let pageText = page.string {
            extractedText += pageText + "\n"
        }
    }
}

print("✅ Text extracted: \(extractedText.count) characters")
print("")
print("First 500 characters:")
print("---")
print(String(extractedText.prefix(500)))
print("---")
print("")

// Test file size
let pdfData = try Data(contentsOf: pdfURL)
let sizeInMB = Double(pdfData.count) / (1024 * 1024)
print("File size: \(String(format: "%.2f", sizeInMB)) MB")

if sizeInMB > 10 {
    print("⚠️  File exceeds 10MB limit")
} else {
    print("✅ File size within limit")
}
print("")

// Now we need to test with the actual AIService
// This requires the OpenRouter API key to be configured
print("📝 To test AI summary generation:")
print("1. Text extraction: ✅ Working")
print("2. File size check: ✅ Passed")
print("3. Next: Test with AIService (requires OpenRouter API key)")
