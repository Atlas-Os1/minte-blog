#!/bin/bash

# Publish approved blog post
# Changes draft: true → draft: false and deploys

set -e

BLOG_DIR="/home/flo/minte-blog"
DATE="${1:-$(date +%Y-%m-%d)}"
FILENAME="${DATE}-building-in-public.mdx"
FILEPATH="${BLOG_DIR}/src/content/posts/${FILENAME}"

if [ ! -f "$FILEPATH" ]; then
  echo "❌ Post not found: $FILEPATH"
  exit 1
fi

echo "📤 Publishing blog post: $FILENAME"

# Change draft: true → draft: false
sed -i 's/draft: true/draft: false/' "$FILEPATH"
echo "✅ Marked as published (draft: false)"

# Git commit and push
cd "$BLOG_DIR"
git add "$FILEPATH"
git commit -m "Post: $(grep '^title:' "$FILEPATH" | sed 's/title: "\(.*\)"/\1/')"
git push origin main

echo "✅ Published and deployed!"
echo ""
echo "🌐 Live at: https://minte-blog.pages.dev/"
echo "🌐 Custom domain (if configured): https://blog.minte.dev/"
