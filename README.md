# Minte.dev Building in Public Blog

Daily blog posts about building projects in public, deployed to `blog.minte.dev`.

## Features

- 📝 **MDX Support** - Write blog posts in Markdown with JSX
- 🚀 **Cloudflare Pages** - Edge deployment for global performance
- 📡 **RSS Feed** - Available at `/rss.xml`
- 🎨 **Social Sharing** - Open Graph and Twitter Card meta tags
- 🗂️ **R2 Storage** - Post storage in Cloudflare R2
- 🔍 **SEO Optimized** - Sitemap, canonical URLs, and meta tags

## Tech Stack

- **Astro** - Static site generator
- **MDX** - Markdown with JSX
- **TypeScript** - Type-safe development
- **Cloudflare Pages** - Hosting and edge deployment
- **R2** - Object storage for posts

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Writing Posts

Create new posts in `src/content/posts/` as `.mdx` files:

```mdx
---
title: "Your Post Title"
description: "Short description for SEO and social sharing"
pubDate: 2026-01-31
author: "Flo"
tags: ["tag1", "tag2"]
draft: false
---

# Your content here

Write your post in Markdown with MDX support!
```

## Deployment

Automatically deployed to Cloudflare Pages on push to main branch.

### Manual Deploy

```bash
npm run build
npx wrangler pages deploy dist --project-name=minte-blog
```

## Environment

- **Production URL**: https://blog.minte.dev
- **R2 Bucket**: blog-posts-prod
- **GitHub Repo**: Atlas-Os1/minte-blog

## Structure

```
src/
├── content/
│   ├── config.ts        # Content collection definitions
│   └── posts/           # Blog posts (MDX files)
├── layouts/
│   ├── BaseLayout.astro # Base HTML layout with meta tags
│   └── PostLayout.astro # Post-specific layout
├── pages/
│   ├── index.astro      # Home page with post list
│   ├── posts/
│   │   └── [...slug].astro  # Dynamic post pages
│   └── rss.xml.ts       # RSS feed generator
└── components/          # Reusable components
```

## License

MIT
