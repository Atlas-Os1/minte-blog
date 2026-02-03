#!/usr/bin/env node

/**
 * Daily Blog Post Generator
 * 
 * Generates "building in public" blog posts from:
 * - Recent memory files
 * - GitHub activity
 * - Project updates
 * 
 * Usage:
 *   node scripts/generate-daily-post.js [--date YYYY-MM-DD]
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

// Parse args
const args = process.argv.slice(2);
const dateArg = args.find(arg => arg.startsWith('--date'));
const targetDate = dateArg ? dateArg.split('=')[1] : new Date().toISOString().split('T')[0];

console.log(`📝 Generating blog post for ${targetDate}...`);

// Read memory file for the day
const memoryPath = `/home/flo/clawd/memory/${targetDate}.md`;
let memoryContent = '';
if (existsSync(memoryPath)) {
  memoryContent = readFileSync(memoryPath, 'utf-8');
  console.log(`✅ Found memory file: ${memoryPath}`);
} else {
  console.log(`⚠️  No memory file found for ${targetDate}`);
}

// Get recent GitHub commits
let gitActivity = '';
try {
  const repos = [
    '/home/flo/clawd',
    '/home/flo/devflo-moltworker',
    '/home/flo/minte-blog'
  ];
  
  const commits = [];
  for (const repo of repos) {
    if (existsSync(repo)) {
      try {
        const log = execSync(
          `cd ${repo} && git log --since="${targetDate} 00:00" --until="${targetDate} 23:59" --pretty=format:"%h - %s" --no-merges`,
          { encoding: 'utf-8' }
        ).trim();
        if (log) {
          const repoName = repo.split('/').pop();
          commits.push(`**${repoName}:**\n${log}`);
        }
      } catch (e) {
        // Repo might not have commits for this day
      }
    }
  }
  
  if (commits.length > 0) {
    gitActivity = commits.join('\n\n');
    console.log(`✅ Found ${commits.length} repos with activity`);
  }
} catch (error) {
  console.log(`⚠️  Error fetching git activity:`, error.message);
}

// Generate blog post content
const postContent = `---
title: "Building in Public - ${targetDate}"
description: "Daily update on projects, experiments, and learnings"
pubDate: ${targetDate}
author: "Flo"
tags: ["building-in-public", "daily", "updates"]
draft: true
---

# Building in Public - ${new Date(targetDate).toLocaleDateString('en-US', { 
  weekday: 'long', 
  year: 'numeric', 
  month: 'long', 
  day: 'numeric' 
})}

${generateContentFromMemory(memoryContent)}

${gitActivity ? `## 🚀 Code Activity\n\n${gitActivity}` : ''}

---

*This post is part of my daily building in public series. Follow along on [Discord](https://discord.gg/clawd) or via [RSS](/rss.xml).*
`;

// Save draft
const postsDir = join(ROOT, 'src', 'content', 'posts');
if (!existsSync(postsDir)) {
  mkdirSync(postsDir, { recursive: true });
}

const filename = `${targetDate}-building-in-public.mdx`;
const filepath = join(postsDir, filename);

writeFileSync(filepath, postContent, 'utf-8');
console.log(`✅ Generated draft post: ${filepath}`);
console.log(`\n📄 Preview:\n${postContent.substring(0, 500)}...\n`);

// Output path for other scripts to use
console.log(`\nFILE_PATH=${filepath}`);

/**
 * Generate blog content from memory file
 */
function generateContentFromMemory(memory) {
  if (!memory) {
    return `## 🔧 What I'm Working On

*Working on various projects across the stack...*

<!-- TODO: Add project updates -->

## 💡 Lessons Learned

*Documenting learnings from today's work...*

<!-- TODO: Add insights -->`;
  }
  
  // Extract sections from memory
  const sections = [];
  
  // Look for project headers
  const projectMatches = memory.match(/## (.+?)(?=\n|$)/g);
  if (projectMatches && projectMatches.length > 0) {
    sections.push('## 🔧 What I Worked On Today\n');
    projectMatches.slice(0, 3).forEach(match => {
      const title = match.replace('## ', '').trim();
      sections.push(`### ${title}\n`);
      
      // Extract a few bullet points from this section
      const sectionRegex = new RegExp(`${match}([\\s\\S]*?)(?=\\n## |$)`);
      const sectionContent = memory.match(sectionRegex);
      if (sectionContent && sectionContent[1]) {
        const bullets = sectionContent[1]
          .split('\n')
          .filter(line => line.trim().startsWith('-') || line.trim().startsWith('*'))
          .slice(0, 5)
          .join('\n');
        sections.push(bullets + '\n');
      }
    });
  }
  
  return sections.join('\n') || '## 🔧 Projects\n\n*Details coming soon...*';
}
