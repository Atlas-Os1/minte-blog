#!/bin/bash

# Auto-publish approved blog post
# Takes a JSON draft and publishes to the Astro blog
# Called when a blog is approved in Discord

set -e

BLOG_DIR="/home/flo/minte-blog"
DATE="${1:-$(date +%Y-%m-%d)}"

# Find the draft
DRAFT_PATH="/home/flo/blog-draft-${DATE}.json"
if [ ! -f "$DRAFT_PATH" ]; then
  DRAFT_PATH="/tmp/blog-draft-${DATE}.json"
fi

if [ ! -f "$DRAFT_PATH" ]; then
  echo "❌ No draft found for ${DATE}"
  echo "Checked: /home/flo/blog-draft-${DATE}.json"
  echo "Checked: /tmp/blog-draft-${DATE}.json"
  exit 1
fi

echo "📄 Found draft: $DRAFT_PATH"

# Parse JSON using jq
TITLE=$(jq -r '.title' "$DRAFT_PATH")
CONTENT=$(jq -r '.content' "$DRAFT_PATH")
TAGS=$(jq -r '.tags | join("\", \"")' "$DRAFT_PATH")
CATEGORY=$(jq -r '.category // "engineering"' "$DRAFT_PATH")

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | head -c 50)
FILENAME="${DATE}-${SLUG}.mdx"
FILEPATH="${BLOG_DIR}/src/content/posts/${FILENAME}"

echo "📝 Creating: $FILENAME"

# Generate MDX with frontmatter
cat > "$FILEPATH" << EOF
---
title: "${TITLE}"
description: "Daily building-in-public update"
pubDate: ${DATE}
author: "Flo"
tags: ["${TAGS}"]
draft: false
---

${CONTENT}
EOF

echo "✅ Created: $FILEPATH"

# Git commit and push
cd "$BLOG_DIR"
git add "$FILEPATH"
git commit -m "Post: ${TITLE}"
git push origin main

echo ""
echo "✅ Published and deploying!"
echo "🌐 Live at: https://blog.minte.dev/"
echo "📝 File: $FILENAME"
