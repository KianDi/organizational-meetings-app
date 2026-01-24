#!/bin/bash

# Full PDF to Summary test

PDF_PATH="/Users/kian/projects/Business Retreat Jan 18 2026 (1).pdf"
API_KEY="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"
ENDPOINT="https://openrouter.ai/api/v1/chat/completions"
MODEL="tngtech/deepseek-r1t2-chimera:free"

echo "📄 Full PDF Summary Generation Test"
echo "===================================="
echo ""
echo "Step 1: Extract text from PDF..."

# Extract text using Swift
cat > /tmp/extract_pdf.swift << 'EOF'
import Foundation
import PDFKit

let pdfPath = CommandLine.arguments[1]
guard let pdfURL = URL(string: "file://\(pdfPath)"),
      let pdfDocument = PDFDocument(url: pdfURL) else {
    print("ERROR: Failed to load PDF")
    exit(1)
}

var extractedText = ""
for i in 0..<pdfDocument.pageCount {
    if let page = pdfDocument.page(at: i) {
        if let pageText = page.string {
            extractedText += pageText + "\n"
        }
    }
}

print(extractedText)
EOF

DOCUMENT_TEXT=$(swift /tmp/extract_pdf.swift "$PDF_PATH" 2>/dev/null)

if [ -z "$DOCUMENT_TEXT" ]; then
    echo "❌ Failed to extract text from PDF"
    exit 1
fi

CHAR_COUNT=$(echo -n "$DOCUMENT_TEXT" | wc -c | tr -d ' ')
echo "✅ Extracted $CHAR_COUNT characters"
echo ""
echo "First 300 characters:"
echo "---"
echo "$DOCUMENT_TEXT" | head -c 300
echo "..."
echo "---"
echo ""

# Escape the document text for JSON
ESCAPED_TEXT=$(echo "$DOCUMENT_TEXT" | jq -Rs .)

echo "Step 2: Generate summary via OpenRouter..."
echo ""

# Create the API request
cat > /tmp/summary_request.json << EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "system",
      "content": "You are a meeting minutes analyzer. Create clear, concise summaries in 200-400 words."
    },
    {
      "role": "user",
      "content": "Analyze this meeting document and create a concise summary.\\n\\nDocument:\\n$ESCAPED_TEXT\\n\\nProvide:\\n1. Brief overview (2-3 sentences)\\n2. Key decisions made\\n3. Important topics discussed\\n4. Next steps\\n\\nFormat as readable paragraphs, not bullet points."
    }
  ],
  "max_tokens": 4096
}
EOF

echo "Sending request (this may take 10-15 seconds)..."

# Make the request
response=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "X-Title: MeetingManager" \
  -d @/tmp/summary_request.json)

# Split response and status code
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo ""
echo "HTTP Status: $http_code"
echo ""

if [ "$http_code" = "200" ]; then
    echo "✅ SUCCESS! Summary generated:"
    echo "================================"
    echo ""
    echo "$body" | jq -r '.choices[0].message.content'
    echo ""
    echo "================================"
    echo ""
    echo "API Usage:"
    echo "$body" | jq '.usage'
else
    echo "❌ Error occurred:"
    echo "$body" | jq .
fi

# Cleanup
rm -f /tmp/extract_pdf.swift /tmp/summary_request.json

echo ""
echo "Test complete!"
