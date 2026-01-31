# Deployment Guide

## Cloudflare Pages Setup

The blog is deployed to Cloudflare Pages with the following configuration:

### Project Details
- **Project Name**: minte-blog
- **Production Branch**: main
- **Production URL**: https://minte-blog.pages.dev
- **Custom Domain**: blog.minte.dev (configure via dashboard)
- **GitHub Repo**: https://github.com/Atlas-Os1/minte-blog

### R2 Storage
- **Bucket Name**: blog-posts-prod
- **Purpose**: Storage for blog posts and assets
- **Location**: Automatically determined (WEUR - Western Europe)

## Custom Domain Setup

To configure the custom domain `blog.minte.dev`:

1. Go to [Cloudflare Dashboard → Pages](https://dash.cloudflare.com/pages)
2. Select the `minte-blog` project
3. Navigate to **Custom domains** tab
4. Click **Set up a custom domain**
5. Enter `blog.minte.dev`
6. Cloudflare will automatically add the necessary DNS records

### DNS Configuration

Cloudflare Pages will add a CNAME record:
```
blog.minte.dev CNAME minte-blog.pages.dev
```

This should be automatically configured when you add the custom domain through the dashboard.

## Automatic Deployments

The blog is configured to automatically deploy when:
- Commits are pushed to the `main` branch
- GitHub will trigger a Cloudflare Pages build

### Manual Deployment

To manually deploy:

```bash
# Build the site
npm run build

# Deploy to Cloudflare Pages
npx wrangler pages deploy dist --project-name=minte-blog
```

## Environment Setup

No environment variables are currently required. The site is fully static.

### Future R2 Integration

If you want to serve blog posts from R2 instead of bundling them:

1. Create a Worker or Pages Function to read from R2
2. Add R2 binding in `wrangler.toml`:
   ```toml
   [[r2_buckets]]
   binding = "BLOG_POSTS"
   bucket_name = "blog-posts-prod"
   ```
3. Update the content collection to fetch from R2

## Monitoring

- **Deployments**: https://dash.cloudflare.com/pages/view/minte-blog
- **Analytics**: Available in Cloudflare Dashboard
- **Build Logs**: Viewable in deployment details

## Troubleshooting

### Build Failures
- Check the build logs in Cloudflare Dashboard
- Ensure all dependencies are in `package.json`
- Verify Node.js version compatibility

### Domain Not Working
- DNS propagation can take up to 48 hours
- Verify CNAME record is correctly pointing to `minte-blog.pages.dev`
- Check Cloudflare SSL/TLS settings (should be "Full" or "Full (strict)")

### RSS Feed Issues
- Ensure `site` is set in `astro.config.mjs`
- Verify all posts have required frontmatter fields
- Check build output for `/rss.xml`
