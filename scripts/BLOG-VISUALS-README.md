# Blog Visual Pipeline

Automated image generation pipeline for blog posts using Atlas-Warhol (Cloudflare FLUX AI).

## Overview

This pipeline generates multiple images per blog post:

1. **Hero image** (1200×630) - Main visual at top of post
2. **Author signature card** (600×200) - Bottom of post  
3. **Charts/infographics** (800×600) - Optional inline content

All images are:
- Generated via Cloudflare Workers AI (FLUX-2-dev with klein-9b fallback)
- Uploaded to R2 bucket: `blog-posts-prod`
- Publicly accessible via: `https://pub-5524a59e160847ab873469954399f28d.r2.dev`
- Returned as JSON for easy embedding

## Usage

### Basic Usage (Hero + Signature only)

```bash
./scripts/generate-blog-visuals.sh \
  "2026-02-03-dual-agent-collaboration" \
  "How Two AI Agents Built This Blog Post Together"
```

### With Charts/Infographics

```bash
./scripts/generate-blog-visuals.sh \
  "2026-02-03-dual-agent-collaboration" \
  "How Two AI Agents Built This Blog Post Together" \
  --with-charts
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<slug>` | Yes | Blog post filename slug (e.g., `2026-02-03-dual-agent-collaboration`) |
| `<title>` | Yes | Blog post title (used for hero image prompt) |
| `--with-charts` | No | Generate charts if blog post mentions data/metrics |

## Output

The script returns a JSON file with public URLs:

```json
{
  "hero": "https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png",
  "signature": "https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/signatures/flo-signature.png",
  "charts": [
    "https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/charts/2026-02-03-dual-agent-collaboration-chart-growth.png"
  ]
}
```

## R2 Bucket Structure

```
blog-posts-prod/
├── assets/
│   ├── heroes/
│   │   └── {slug}-hero.png         # Hero images (1200×630)
│   ├── signatures/
│   │   └── flo-signature.png       # Reusable signature card (600×200)
│   └── charts/
│       └── {slug}-{name}.png       # Charts/infographics (800×600)
```

## Image Specifications

### Hero Image
- **Dimensions:** 1200×630 (Open Graph standard)
- **Prompt:** Generated from blog title
- **Style:** Glassmorphism, dark theme, orange/black accents
- **Quality:** 30 steps (high quality)
- **Location:** `assets/heroes/{slug}-hero.png`

### Signature Card
- **Dimensions:** 600×200
- **Content:** "Written by Flo - Atlas-OS Agent"
- **Style:** Orange/black branding, modern tech aesthetic
- **Quality:** 25 steps
- **Location:** `assets/signatures/flo-signature.png` (reusable)
- **Behavior:** Generated once, reused across all posts

### Charts/Infographics
- **Dimensions:** 800×600
- **Trigger:** Only if blog post contains data/metrics keywords
- **Keywords:** `chart`, `graph`, `metric`, `data`, `statistic`, `percentage`, `%`
- **Style:** Modern infographic, glassmorphism design
- **Quality:** 25 steps
- **Location:** `assets/charts/{slug}-{chart-name}.png`

## Requirements

### Environment Variables

```bash
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
export CLOUDFLARE_WORKERS_AI_TOKEN="your-workers-ai-token"
```

### Dependencies

- Node.js + npm (for `wrangler`)
- Python 3 (for `atlas-warhol`)
- Cloudflare Wrangler CLI
- Atlas-Warhol skill at `/home/flo/.clawdbot/skills/frontend/atlas-warhol`

## Integration Examples

### Embed in MDX Blog Post

```mdx
---
title: "How Two AI Agents Built This Blog Post Together"
---

![Hero Image](https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png)

Your blog content here...

![Growth Chart](https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/charts/2026-02-03-dual-agent-collaboration-chart-growth.png)

More content...

---

![Signature](https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/signatures/flo-signature.png)
```

### Meta Tags for Social Sharing

```html
<meta property="og:image" content="https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:image" content="https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png" />
```

## Workflow

1. **Generate images:**
   ```bash
   ./scripts/generate-blog-visuals.sh "slug" "title" --with-charts
   ```

2. **Copy JSON output** to your clipboard

3. **Embed URLs in blog post:**
   - Add hero image at top
   - Insert charts inline where relevant
   - Add signature card at bottom

4. **Add meta tags** for social sharing (hero image)

5. **Publish post** using existing `publish-post.sh` script

## Customization

### Change Hero Prompt Style

Edit line ~92 in `generate-blog-visuals.sh`:

```bash
HERO_PROMPT="Your custom prompt style for '$TITLE'"
```

### Change Signature Card

Edit line ~167 in `generate-blog-visuals.sh`:

```bash
SIGNATURE_PROMPT="Your custom signature card prompt"
```

### Add More Chart Types

Add additional chart generation blocks after line ~230:

```bash
# Generate architecture diagram
ARCH_PROMPT="Technical architecture diagram for '$TITLE'"
python3 scripts/generate_enhanced.py --prompt "$ARCH_PROMPT" --width 800 --height 600
```

## Troubleshooting

### Images Not Accessible (404)

**Problem:** Images return 404 errors from R2 public URL

**Solution:** Ensure wrangler uses `--remote` flag for uploads
```bash
npx wrangler r2 object put blog-posts-prod/assets/heroes/test.png \
  --file=test.png --remote
```

### Generation Failed

**Problem:** FLUX-2-dev model timeout or error

**Solution:** Script automatically falls back to FLUX-2-klein-9b. Check logs for:
```
🔄 Primary model failed, trying fallback: @cf/black-forest-labs/flux-2-klein-9b
```

### Signature Card Regenerates Every Time

**Problem:** Signature detection failing

**Solution:** Check R2 for existing signature:
```bash
npx wrangler r2 object get blog-posts-prod/assets/signatures/flo-signature.png \
  --file=/tmp/test.png --remote
```

### Large File Size

**Problem:** Hero images >500KB

**Solution:** Reduce quality steps or dimensions in script:
```bash
python3 scripts/generate_enhanced.py --steps 20  # Lower quality
```

## Performance

| Step | Time | Notes |
|------|------|-------|
| Hero generation | ~15-30s | FLUX-2-dev |
| Signature generation | ~10-20s | Once only, reused |
| Chart generation | ~10-20s per chart | Optional |
| R2 upload | ~2-5s | Per image |
| **Total** | **~30-60s** | For complete pipeline |

## Examples

### Successful Run

```
═══════════════════════════════════════════════════════════
🎨 BLOG VISUAL PIPELINE
═══════════════════════════════════════════════════════════

📝 Blog Post: 2026-02-03-dual-agent-collaboration
🏷️  Title: How Two AI Agents Built This Blog Post Together
📊 Charts: Yes
💾 R2 Bucket: blog-posts-prod
🌐 Public URL: https://pub-5524a59e160847ab873469954399f28d.r2.dev

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🖼️  STEP 1: Generating Hero Image
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Hero image generated: 2026-02-03-dual-agent-collaboration-hero.png
✅ Hero uploaded: https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✍️  STEP 2: Author Signature Card
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Signature card already exists in R2 (reusing)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 STEP 3: Generating Charts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 Detected data/metrics in blog post
✅ Chart uploaded: https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/charts/2026-02-03-dual-agent-collaboration-chart-growth.png

═══════════════════════════════════════════════════════════
✨ VISUAL PIPELINE COMPLETE
═══════════════════════════════════════════════════════════

📄 JSON Output:
{
  "hero": "https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/heroes/2026-02-03-dual-agent-collaboration-hero.png",
  "signature": "https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/signatures/flo-signature.png",
  "charts": ["https://pub-5524a59e160847ab873469954399f28d.r2.dev/assets/charts/2026-02-03-dual-agent-collaboration-chart-growth.png"]
}

✅ Done!
```

## Future Enhancements

### Planned Features

- [ ] **Batch processing** - Generate visuals for multiple posts
- [ ] **Style templates** - Pre-defined visual styles per topic
- [ ] **Smart chart detection** - AI analyzes post content to suggest charts
- [ ] **Social media variants** - Generate Twitter/LinkedIn card sizes
- [ ] **Animation support** - Generate animated GIFs for hero images
- [ ] **Brand consistency** - Enforce color schemes from brand guide

### Integration Ideas

- Auto-run on git commit hooks
- Integrate with `publish-post.sh` workflow
- Add to GitHub Actions for automated deployment
- Generate preview images for drafts

## License

Part of the minte-blog project. See main repository for license details.

## Support

For issues or questions:
- Check the Troubleshooting section above
- Review atlas-warhol skill documentation
- Contact: Flo (Atlas-OS Agent)

---

*Generated by Atlas-Warhol • Powered by Cloudflare Workers AI (FLUX-2-dev)*
