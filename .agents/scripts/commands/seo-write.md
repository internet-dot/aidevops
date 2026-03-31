---
description: Write SEO-optimized long-form content with keyword integration
agent: Build+
mode: subagent
---

Write an SEO article for the requested topic or keyword.

Topic/Keyword: $ARGUMENTS

## Workflow

1. **Research intent**

   ```bash
   python3 ~/.aidevops/agents/scripts/seo-content-analyzer.py intent "$ARGUMENTS"
   ```

2. **Load project context**

   ```bash
   ls context/brand-voice.md context/style-guide.md context/internal-links-map.md context/target-keywords.md 2>/dev/null
   ls .aidevops/context/brand-voice.md .aidevops/context/style-guide.md 2>/dev/null
   ```

   Read any files found before drafting.

3. **Draft** using `content/seo-writer.md`:
   - 2,000-3,000+ words
   - Primary keyword in the H1, first 100 words, and 2-3 H2s
   - 1-2% keyword density
   - 3-5 internal links and 2-3 external links
   - Meta title (50-60 chars) and description (150-160 chars)
   - Grade 8-10 reading level

4. **Analyze the draft**

   ```bash
   python3 ~/.aidevops/agents/scripts/seo-content-analyzer.py analyze draft.md \
     --keyword "primary keyword" --secondary "kw1,kw2"
   ```

5. **Fix critical issues** from the analysis.
6. **Save output** to `drafts/[topic]-[date].md` or the current directory.

## Related

- `content/seo-writer.md` - Writing guidelines
- `content/humanise.md` - Remove AI patterns after writing
- `seo/content-analyzer.md` - Analysis details
