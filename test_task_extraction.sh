#!/bin/bash

# Test task extraction with JSON mode

PDF_PATH="/Users/kian/projects/Business Retreat Jan 18 2026 (1).pdf"
API_KEY="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"
ENDPOINT="https://openrouter.ai/api/v1/chat/completions"
MODEL="tngtech/deepseek-r1t2-chimera:free"

echo "🔧 Testing Task Extraction with JSON Mode"
echo "=========================================="
echo ""

# Extract text from PDF
cat > /tmp/extract_pdf.swift << 'EOF'
import Foundation
import PDFKit

let pdfPath = CommandLine.arguments[1]
guard let pdfURL = URL(string: "file://\(pdfPath)"),
      let pdfDocument = PDFDocument(url: pdfURL) else {
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
ESCAPED_TEXT=$(echo "$DOCUMENT_TEXT" | jq -Rs .)

echo "Step 1: Sending task extraction request with JSON mode..."

# Create the API request with JSON mode
cat > /tmp/task_request.json << EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "system",
      "content": "You are a task extraction specialist. Extract action items from meeting documents. Match assignee names to the provided member list, handling typos and nicknames. If no assignee mentioned, leave assigneeName as null. If no due date mentioned, leave dueDate as null. Infer priority from urgency language (urgent/ASAP = high, normal = medium, backlog/someday = low)."
    },
    {
      "role": "user",
      "content": "Extract all action items and tasks from this meeting document.\\n\\nOrganization members:\\nAung Ryan Logan (email: aung@example.com)\\nBrian H. (email: brian@example.com)\\nAnt Kian (email: kian@example.com)\\nThai Eric Yoon (email: thai@example.com)\\nAlex Alp Luis (email: alex@example.com)\\n\\nDocument:\\n$ESCAPED_TEXT\\n\\nFor each task, extract:\\n- title: Clear, actionable task description\\n- assigneeName: Person assigned (match to members list above, or null if unclear)\\n- dueDate: Deadline in ISO8601 format if mentioned (YYYY-MM-DD), or null\\n- priority: \\"high\\", \\"medium\\", or \\"low\\" based on urgency language\\n- context: Original text snippet where task was mentioned\\n\\nReturn JSON with a \\"tasks\\" array containing these fields."
    }
  ],
  "max_tokens": 4096,
  "response_format": { "type": "json_object" }
}
EOF

echo "Making API call (this may take 15-20 seconds)..."

# Make the request
response=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "X-Title: MeetingManager" \
  -d @/tmp/task_request.json)

# Split response and status code
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo ""
echo "HTTP Status: $http_code"
echo ""

if [ "$http_code" = "200" ]; then
    echo "✅ API call successful"
    echo ""
    echo "Raw API Response:"
    echo "================"
    echo "$body" | jq .
    echo ""
    echo "Extracted Content (what AIService sees):"
    echo "========================================"
    content=$(echo "$body" | jq -r '.choices[0].message.content')
    echo "$content"
    echo ""

    echo "Testing JSON Parsing (as app would do):"
    echo "======================================="
    # Try to parse it as the app would
    echo "$content" | jq . > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Valid JSON structure"
        echo ""
        echo "Parsed Tasks:"
        echo "$content" | jq '.tasks'
    else
        echo "❌ INVALID JSON - This is the error!"
        echo ""
        echo "Content is not valid JSON:"
        echo "$content"
    fi
else
    echo "❌ API Error:"
    echo "$body" | jq .
fi

# Cleanup
rm -f /tmp/extract_pdf.swift /tmp/task_request.json

echo ""
echo "Test complete!"
