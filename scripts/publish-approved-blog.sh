#!/bin/bash
# Publish an approved blog post
# Usage: publish-approved-blog.sh [YYYY-MM-DD]
# Converts JSON draft → MDX, commits, pushes → triggers CF Pages rebuild

set -e

BLOG_DIR="/home/flo/minte-blog"
DATE="${1:-$(date +%Y-%m-%d)}"
DRAFT="/tmp/blog-draft-${DATE}.json"

if [ ! -f "$DRAFT" ]; then
  echo "❌ Draft not found: $DRAFT"
  exit 1
fi

if [ ! -s "$DRAFT" ]; then
  echo "❌ Draft is empty: $DRAFT"
  exit 1
fi

# Extract fields from JSON
TITLE=$(jq -r '.title' "$DRAFT")
CONTENT=$(jq -r '.content' "$DRAFT")
TAGS=$(jq -r '.tags | @json' "$DRAFT")
CATEGORY=$(jq -r '.category // "development"' "$DRAFT")

# Create slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="${DATE}-${SLUG}.mdx"
FILEPATH="${BLOG_DIR}/src/content/posts/${FILENAME}"

echo "📝 Publishing: $TITLE"
echo "   File: $FILENAME"

# Build MDX frontmatter
cat > "$FILEPATH" << EOF
---
title: "${TITLE}"
description: "Daily building in public log - ${DATE}"
pubDate: ${DATE}
author: "Flo"
tags: ${TAGS}
category: "${CATEGORY}"
draft: false
---

${CONTENT}
EOF

echo "✅ MDX created: $FILEPATH"

# Git commit and push
cd "$BLOG_DIR"
git add "$FILEPATH"
git commit -m "📝 ${DATE}: ${TITLE}"
git push origin main

echo "✅ Pushed to GitHub"
echo "🚀 Cloudflare Pages will auto-deploy in ~1 minute"
echo ""
echo "🌐 Live at: https://blog.minte.dev/${SLUG}"

# Archive the draft
mv "$DRAFT" "/tmp/blog-draft-${DATE}-published.json"
echo "📦 Draft archived"
