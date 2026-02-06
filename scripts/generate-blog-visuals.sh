#!/bin/bash

################################################################################
# Blog Visual Pipeline - Generate Images for Blog Posts
#
# Generates multiple images per blog post:
# 1. Hero image (1200x630) - main visual at top of post
# 2. Author signature card (600x200) - bottom of post
# 3. Charts/infographics (800x600) - optional inline content
#
# Uploads to R2 bucket: blog-posts-prod
# Returns JSON with public URLs for easy embedding
#
# Usage:
#   ./generate-blog-visuals.sh <slug> <title> [--with-charts]
#
# Example:
#   ./generate-blog-visuals.sh "2026-02-03-dual-agent-collaboration" \
#     "How Two AI Agents Built This Blog Post Together" \
#     --with-charts
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BLOG_DIR="/home/flo/minte-blog"
ATLAS_WARHOL_DIR="/home/flo/.clawdbot/skills/frontend/atlas-warhol"
OUTPUT_DIR="/tmp/blog-visuals-$$"
R2_BUCKET="blog-posts-prod"
R2_PUBLIC_URL="https://pub-5524a59e160847ab873469954399f28d.r2.dev"

# Check for required environment variables
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$CLOUDFLARE_WORKERS_AI_TOKEN" ]; then
    echo -e "${RED}❌ Error: Missing required environment variables${NC}"
    echo "   Required: CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_WORKERS_AI_TOKEN"
    exit 1
fi

# Parse arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <slug> <title> [--with-charts]${NC}"
    echo ""
    echo "Example:"
    echo "  $0 '2026-02-03-dual-agent-collaboration' \\"
    echo "    'How Two AI Agents Built This Blog Post Together' \\"
    echo "    --with-charts"
    exit 1
fi

SLUG="$1"
TITLE="$2"
WITH_CHARTS=false

# Check for --with-charts flag
if [ "$3" = "--with-charts" ]; then
    WITH_CHARTS=true
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🎨 BLOG VISUAL PIPELINE${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📝 Blog Post:${NC} $SLUG"
echo -e "${CYAN}🏷️  Title:${NC} $TITLE"
echo -e "${CYAN}📊 Charts:${NC} $([ "$WITH_CHARTS" = true ] && echo "Yes" || echo "No")"
echo -e "${CYAN}💾 R2 Bucket:${NC} $R2_BUCKET"
echo -e "${CYAN}🌐 Public URL:${NC} $R2_PUBLIC_URL"
echo ""

# Initialize JSON output
JSON_OUTPUT="{"

################################################################################
# 1. GENERATE HERO IMAGE (1200x630)
################################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🖼️  STEP 1: Generating Hero Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create hero image prompt based on blog title
HERO_PROMPT="Modern tech blog hero image for article titled '$TITLE', professional glassmorphism design, dark theme with orange and black accents, tech aesthetic, abstract geometric patterns, futuristic, high quality, 16:9 aspect ratio"

echo -e "${CYAN}💭 Prompt:${NC} $HERO_PROMPT"
echo ""

# Generate hero image using atlas-warhol
cd "$ATLAS_WARHOL_DIR"

HERO_FILE="${SLUG}-hero"

echo -e "${YELLOW}⏳ Generating with FLUX-2-dev...${NC}"

python3 scripts/generate_enhanced.py \
    --prompt "$HERO_PROMPT" \
    --width 1200 \
    --height 630 \
    --steps 30 \
    --output "$HERO_FILE" \
    --account-id "$CLOUDFLARE_ACCOUNT_ID" \
    --api-token "$CLOUDFLARE_WORKERS_AI_TOKEN"

if [ ! -f "output/${HERO_FILE}.png" ]; then
    echo -e "${RED}❌ Error: Hero image generation failed${NC}"
    exit 1
fi

# Move to output directory
mv "output/${HERO_FILE}.png" "$OUTPUT_DIR/"

echo -e "${GREEN}✅ Hero image generated: ${HERO_FILE}.png${NC}"
echo ""

# Upload hero to R2
echo -e "${YELLOW}📤 Uploading hero image to R2...${NC}"

cd "$BLOG_DIR"
npx wrangler r2 object put "$R2_BUCKET/assets/heroes/${HERO_FILE}.png" \
    --file="$OUTPUT_DIR/${HERO_FILE}.png" \
    --content-type="image/png" \
    --remote 2>&1 | grep -v "wrangler"

HERO_URL="${R2_PUBLIC_URL}/assets/heroes/${HERO_FILE}.png"

echo -e "${GREEN}✅ Hero uploaded: ${HERO_URL}${NC}"
echo ""

# Add to JSON output
JSON_OUTPUT="${JSON_OUTPUT}\"hero\": \"${HERO_URL}\""

################################################################################
# 2. GENERATE/COPY AUTHOR SIGNATURE CARD (600x200)
################################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✍️  STEP 2: Author Signature Card${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if signature already exists in R2
SIGNATURE_EXISTS=$(npx wrangler r2 object get "$R2_BUCKET/assets/signatures/flo-signature.png" \
    --file=/dev/null --remote 2>&1 | grep -c "success" || echo "0")

if [ "$SIGNATURE_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Signature card already exists in R2 (reusing)${NC}"
    SIGNATURE_URL="${R2_PUBLIC_URL}/assets/signatures/flo-signature.png"
else
    echo -e "${YELLOW}🎨 Generating new signature card...${NC}"
    
    SIGNATURE_PROMPT="Author signature card with text 'Written by Flo - Atlas-OS Agent', modern design, orange and black color scheme, tech aesthetic, clean typography, professional, 600x200 pixels, glassmorphism style"
    
    cd "$ATLAS_WARHOL_DIR"
    
    python3 scripts/generate_enhanced.py \
        --prompt "$SIGNATURE_PROMPT" \
        --width 600 \
        --height 200 \
        --steps 25 \
        --output "flo-signature" \
        --account-id "$CLOUDFLARE_ACCOUNT_ID" \
        --api-token "$CLOUDFLARE_WORKERS_AI_TOKEN"
    
    if [ ! -f "output/flo-signature.png" ]; then
        echo -e "${RED}❌ Error: Signature generation failed${NC}"
        exit 1
    fi
    
    # Move to output directory
    mv "output/flo-signature.png" "$OUTPUT_DIR/"
    
    # Upload to R2
    cd "$BLOG_DIR"
    npx wrangler r2 object put "$R2_BUCKET/assets/signatures/flo-signature.png" \
        --file="$OUTPUT_DIR/flo-signature.png" \
        --content-type="image/png" \
        --remote 2>&1 | grep -v "wrangler"
    
    SIGNATURE_URL="${R2_PUBLIC_URL}/assets/signatures/flo-signature.png"
    
    echo -e "${GREEN}✅ Signature uploaded: ${SIGNATURE_URL}${NC}"
fi

echo ""

# Add to JSON output
JSON_OUTPUT="${JSON_OUTPUT}, \"signature\": \"${SIGNATURE_URL}\""

################################################################################
# 3. GENERATE CHARTS (OPTIONAL)
################################################################################

if [ "$WITH_CHARTS" = true ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 STEP 3: Generating Charts${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Read blog post content to detect data/metrics
    BLOG_FILE="$BLOG_DIR/src/content/posts/${SLUG}.mdx"
    
    if [ ! -f "$BLOG_FILE" ]; then
        echo -e "${YELLOW}⚠️  Blog post file not found: ${BLOG_FILE}${NC}"
        echo -e "${YELLOW}   Skipping chart generation${NC}"
    else
        # Check if blog mentions data/metrics keywords
        if grep -qiE "(chart|graph|metric|data|statistic|percentage|%|1,445%|40%)" "$BLOG_FILE"; then
            echo -e "${CYAN}📈 Detected data/metrics in blog post${NC}"
            echo ""
            
            # Generate example chart based on blog content
            CHART_PROMPT="Data visualization chart showing multi-agent system growth statistics, modern infographic style, orange and black color scheme, clean and professional, 800x600 pixels, glassmorphism design"
            
            cd "$ATLAS_WARHOL_DIR"
            
            CHART_FILE="${SLUG}-chart-growth"
            
            echo -e "${YELLOW}⏳ Generating chart: growth statistics...${NC}"
            
            python3 scripts/generate_enhanced.py \
                --prompt "$CHART_PROMPT" \
                --width 800 \
                --height 600 \
                --steps 25 \
                --output "$CHART_FILE" \
                --account-id "$CLOUDFLARE_ACCOUNT_ID" \
                --api-token "$CLOUDFLARE_WORKERS_AI_TOKEN"
            
            if [ -f "output/${CHART_FILE}.png" ]; then
                mv "output/${CHART_FILE}.png" "$OUTPUT_DIR/"
                
                # Upload to R2
                cd "$BLOG_DIR"
                npx wrangler r2 object put "$R2_BUCKET/assets/charts/${CHART_FILE}.png" \
                    --file="$OUTPUT_DIR/${CHART_FILE}.png" \
                    --content-type="image/png" \
                    --remote 2>&1 | grep -v "wrangler"
                
                CHART_URL="${R2_PUBLIC_URL}/assets/charts/${CHART_FILE}.png"
                
                echo -e "${GREEN}✅ Chart uploaded: ${CHART_URL}${NC}"
                
                # Add to JSON output
                JSON_OUTPUT="${JSON_OUTPUT}, \"charts\": [\"${CHART_URL}\"]"
            else
                echo -e "${RED}❌ Chart generation failed${NC}"
                JSON_OUTPUT="${JSON_OUTPUT}, \"charts\": []"
            fi
        else
            echo -e "${YELLOW}ℹ️  No data/metrics detected in blog post${NC}"
            echo -e "${YELLOW}   Skipping chart generation${NC}"
            JSON_OUTPUT="${JSON_OUTPUT}, \"charts\": []"
        fi
    fi
    
    echo ""
else
    JSON_OUTPUT="${JSON_OUTPUT}, \"charts\": []"
fi

################################################################################
# 4. OUTPUT RESULTS
################################################################################

# Close JSON
JSON_OUTPUT="${JSON_OUTPUT}}"

# Save JSON to file
JSON_FILE="$OUTPUT_DIR/generated-images.json"
echo "$JSON_OUTPUT" | python3 -m json.tool > "$JSON_FILE"

echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}✨ VISUAL PIPELINE COMPLETE${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📄 JSON Output:${NC}"
cat "$JSON_FILE"
echo ""
echo -e "${CYAN}💾 Local files saved to:${NC} $OUTPUT_DIR"
echo -e "${CYAN}🌐 R2 bucket:${NC} $R2_BUCKET"
echo -e "${CYAN}🔗 Public base URL:${NC} $R2_PUBLIC_URL"
echo ""
echo -e "${YELLOW}📋 Copy this JSON to embed images in your blog post:${NC}"
echo ""
cat "$JSON_FILE"
echo ""
echo -e "${GREEN}✅ Done!${NC}"
echo ""

# Cleanup option
read -p "$(echo -e ${CYAN}Delete local files? [y/N]:${NC} )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$OUTPUT_DIR"
    echo -e "${GREEN}✅ Cleaned up local files${NC}"
else
    echo -e "${YELLOW}ℹ️  Local files kept at: $OUTPUT_DIR${NC}"
fi

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
