#!/bin/bash

# Blog Post Approval Request Script
# Sends draft blog post to Telegram for approval

set -e

BLOG_DIR="/home/flo/minte-blog"
DATE="${1:-$(date +%Y-%m-%d)}"
FILENAME="${DATE}-building-in-public.mdx"
FILEPATH="${BLOG_DIR}/src/content/posts/${FILENAME}"

if [ ! -f "$FILEPATH" ]; then
  echo "❌ Draft post not found: $FILEPATH"
  exit 1
fi

echo "📤 Requesting approval for: $FILENAME"

# Extract title and first few lines of content
TITLE=$(grep '^title:' "$FILEPATH" | sed 's/title: "\(.*\)"/\1/')
PREVIEW=$(sed -n '/^---$/,/^---$/!p' "$FILEPATH" | head -20)

# Create approval message
MESSAGE="📝 **Daily Blog Post Ready for Review**

**Title:** $TITLE
**Date:** $DATE
**File:** $FILENAME

**Preview:**
\`\`\`
$PREVIEW
\`\`\`

**Actions:**
• Reply \`approve blog\` to publish
• Reply \`reject blog\` to discard
• Reply \`edit blog [changes]\` to request edits

**Full preview:** https://minte-blog.pages.dev/ (after approval)"

# Send via clawdbot message tool
# Note: This requires clawdbot CLI or we call through the gateway
echo "$MESSAGE" > /tmp/blog-approval-message.txt

echo "✅ Approval request ready. Use clawdbot message tool to send to Telegram."
echo ""
echo "File: /tmp/blog-approval-message.txt"
echo ""
cat /tmp/blog-approval-message.txt
