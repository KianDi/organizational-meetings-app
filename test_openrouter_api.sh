#!/bin/bash

# Test OpenRouter API with actual request

API_KEY="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"
ENDPOINT="https://openrouter.ai/api/v1/chat/completions"
MODEL="tngtech/deepseek-r1t2-chimera:free"

echo "🧪 Testing OpenRouter API..."
echo ""

# Create test request with small sample
cat > /tmp/test_request.json << 'EOF'
{
  "model": "tngtech/deepseek-r1t2-chimera:free",
  "messages": [
    {
      "role": "system",
      "content": "You are a meeting minutes analyzer. Create clear, concise summaries in 200-400 words."
    },
    {
      "role": "user",
      "content": "Analyze this meeting document and create a concise summary.\n\nDocument:\nBusiness Retreat Spring 2026\n18 JANUARY 2025\nAttendance: Aung Ryan Logan, Brian H., Ant Kian, Thai Eric Yoon, Alex Alp Luis\n\nKey Topics:\n- Project updates\n- Budget review\n- Team assignments\n\nProvide:\n1. Brief overview (2-3 sentences)\n2. Key decisions made\n3. Important topics discussed\n4. Next steps\n\nFormat as readable paragraphs, not bullet points."
    }
  ],
  "max_tokens": 4096
}
EOF

echo "Request payload:"
cat /tmp/test_request.json | jq .
echo ""
echo "Sending request to OpenRouter..."
echo ""

# Make the request
response=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "X-Title: MeetingManager" \
  -d @/tmp/test_request.json)

# Split response and status code
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "HTTP Status: $http_code"
echo ""

if [ "$http_code" = "200" ]; then
    echo "✅ Success! Response:"
    echo "$body" | jq .
    echo ""
    echo "Content:"
    echo "$body" | jq -r '.choices[0].message.content'
else
    echo "❌ Error response:"
    echo "$body" | jq .
fi

# Cleanup
rm /tmp/test_request.json
