---
name: keyword-mapper
description: Keyword placement analysis, density mapping, and distribution optimization
mode: subagent
tools:
  read: true
  write: false
  edit: false
  bash: true
  glob: true
  grep: true
  webfetch: false
  task: true
---

# Keyword Mapper

- **Input**: Article content, primary keyword, secondary keywords
- **Output**: Distribution heatmap, gap analysis, revision suggestions
- **Script**: `seo-content-analyzer.py keywords`

## Run Analysis

```bash
python3 ~/.aidevops/agents/scripts/seo-content-analyzer.py keywords article.md \
  --keyword "primary keyword" \
  --secondary "secondary1,secondary2,secondary3"
```

## Density Status

| Status | Density | Action |
|--------|---------|--------|
| `too_low` | < 0.75% | Add more natural mentions |
| `slightly_low` | 0.75-1.2% | Add a few more mentions |
| `optimal` | 1.2-1.8% | No changes needed |
| `slightly_high` | 1.8-2.25% | Replace some with synonyms |
| `too_high` | > 2.25% | Remove instances, risk of stuffing |

## Critical Placements

| Location | Priority | Why |
|----------|----------|-----|
| H1 heading | Critical | Primary ranking signal |
| First 100 words | Critical | Confirms topic relevance |
| 2-3 H2 headings | High | Section-level relevance |
| Conclusion | Medium | Reinforces topic |
| Meta title | Critical | SERP display |
| Meta description | High | SERP display, bold matching |

## Distribution (per-section heatmap)

- **Introduction**: Higher density (establish topic)
- **Body sections**: Even distribution (1-2 mentions per section)
- **Conclusion**: Moderate density (reinforce topic)
- **No section**: Zero mentions (gap to fill)

## Stuffing Detection

- Overall density > 2.5% (medium risk) or > 3% (high risk)
- Per-paragraph density > 5% (concentrated stuffing)
- 3+ consecutive sentences with keyword (unnatural repetition)

## LSI Keywords

Semantically related terms discovered from content. Use to replace primary keyword instances with variations, add topical depth, and cover related queries.

## Revision Workflow

1. Run analysis
2. Fix critical placement gaps first
3. Adjust density if outside 1-2% range
4. Add LSI keywords for topical coverage
5. Re-run to verify

## Integration

- Feeds into `seo/content-analyzer.md` comprehensive analysis
- Works with `content/seo-writer.md` during writing
- Uses data from `seo/keyword-research.md`
