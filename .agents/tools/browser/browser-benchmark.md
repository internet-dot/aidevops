---
description: Run browser tool benchmarks to compare performance across all installed tools
mode: subagent
tools:
  read: true
  write: true
  edit: true
  bash: true
  glob: true
  grep: true
  task: true
---

# Browser Tool Benchmarking Agent

Run standardised benchmarks across all browser automation tools and update documentation with results.

## Quick Start

```bash
/browser-benchmark              # Run all benchmarks
/browser-benchmark playwright   # Run specific tool only
/browser-benchmark --test navigate
/browser-benchmark --update-docs
```

## Test Suite

Run each test 3 times per tool, report median. All tests use `https://the-internet.herokuapp.com`.

| Test | Playwright | dev-browser | agent-browser | Crawl4AI | Playwriter | Stagehand |
|------|-----------|-------------|---------------|----------|------------|-----------|
| Navigate + Screenshot | `page.goto()` + `page.screenshot()` | TSX via bun | `open` + `screenshot` | `arun(screenshot=True)` | CDP + `page.screenshot()` | `page.goto()` + `page.screenshot()` |
| Form Fill (4 fields) | `page.fill()` x2 + `page.click()` | TSX fill/click | `fill` + `click` | N/A | CDP fill/click | `stagehand.act("fill...")` |
| Data Extraction (5 items) | `page.$$eval()` | TSX `$$eval()` | `eval` CLI | `JsonCssExtractionStrategy` | CDP `$$eval()` | `stagehand.extract()` |
| Multi-step (click+nav) | `page.click()` + `waitForURL()` | TSX click+wait | `click`+`wait`+`get url` | N/A | CDP click+wait | `stagehand.act("click...")` |
| Reliability (3 runs) | Same as Navigate x3 | Same x3 | Same x3 | Same x3 | Same x3 | Same x3 |

## Prerequisites Check

```bash
#!/bin/bash
echo "=== Browser Tool Availability ==="

if command -v npx &>/dev/null && [ -d ~/.aidevops/playwright-bench/node_modules/playwright ]; then
  echo "[OK] Playwright direct"
else
  echo "[--] Playwright direct (run: mkdir -p ~/.aidevops/playwright-bench && cd ~/.aidevops/playwright-bench && npm init -y && npm i playwright)"
fi

if [ -d ~/.aidevops/dev-browser/skills/dev-browser ]; then
  if curl -s --max-time 2 http://localhost:9222/json/version &>/dev/null; then
    echo "[OK] dev-browser (server running)"
  else
    echo "[!!] dev-browser (installed, server not running - run: dev-browser-helper.sh start-headless)"
  fi
else
  echo "[--] dev-browser (run: dev-browser-helper.sh setup)"
fi

command -v agent-browser &>/dev/null && echo "[OK] agent-browser" || echo "[--] agent-browser (run: agent-browser-helper.sh setup)"

[ -f ~/.aidevops/crawl4ai-venv/bin/python ] && echo "[OK] Crawl4AI (venv)" || \
  echo "[--] Crawl4AI (run: python3 -m venv ~/.aidevops/crawl4ai-venv && source ~/.aidevops/crawl4ai-venv/bin/activate && pip install crawl4ai)"

npx playwriter --version &>/dev/null 2>&1 && echo "[!!] Playwriter (needs extension active - check localhost:19988)" || \
  echo "[--] Playwriter (run: npm i -g playwriter)"

[ -d ~/.aidevops/stagehand-bench/node_modules/@browserbasehq/stagehand ] && \
  echo "[OK] Stagehand (needs OPENAI_API_KEY or ANTHROPIC_API_KEY)" || \
  echo "[--] Stagehand (run: mkdir -p ~/.aidevops/stagehand-bench && cd ~/.aidevops/stagehand-bench && npm init -y && npm i @browserbasehq/stagehand)"
```

## Reference Benchmark: Playwright

All tools run the same 4 tests against the same URLs. Playwright is the reference implementation — other tools adapt the API calls shown in the tool-specific section below.

```javascript
// ~/.aidevops/.agent-workspace/work/browser-bench/bench-playwright.mjs
import { chromium } from 'playwright';

const TESTS = {
  async navigate(page) {
    await page.goto('https://the-internet.herokuapp.com/');
    await page.screenshot({ path: '/tmp/bench-pw-nav.png' });
  },
  async formFill(page) {
    await page.goto('https://the-internet.herokuapp.com/login');
    await page.fill('#username', 'tomsmith');
    await page.fill('#password', 'SuperSecretPassword!');
    await page.click('button[type="submit"]');
    await page.waitForURL('**/secure');
  },
  async extract(page) {
    await page.goto('https://the-internet.herokuapp.com/challenging_dom');
    const rows = await page.$$eval('table tbody tr', trs => trs.slice(0, 5).map(tr => tr.textContent.trim()));
    if (rows.length < 5) throw new Error('Expected 5+ rows');
  },
  async multiStep(page) {
    await page.goto('https://the-internet.herokuapp.com/');
    await page.click('a[href="/abtest"]');
    await page.waitForURL('**/abtest');
    const title = await page.title();
    if (!title) throw new Error('No title on target page');
  }
};

async function run() {
  const browser = await chromium.launch({ headless: true });
  const results = {};
  for (const [name, fn] of Object.entries(TESTS)) {
    const times = [];
    for (let i = 0; i < 3; i++) {
      const page = await browser.newPage();
      const start = performance.now();
      try { await fn(page); times.push(((performance.now() - start) / 1000).toFixed(2)); }
      catch (e) { times.push(`ERR: ${e.message}`); }
      await page.close();
    }
    results[name] = times;
  }
  await browser.close();
  console.log(JSON.stringify(results, null, 2));
}
run();
```

## Tool-Specific API Adaptations

Each tool implements the same 4 tests. Below are the setup/teardown and API differences from the Playwright reference.

### dev-browser

```typescript
// Run via: cd ~/.aidevops/dev-browser/skills/dev-browser && bun x tsx bench.ts
import { connect, waitForPageLoad } from "@/client.js";
import type { Page } from "playwright";

// Setup: const client = await connect("http://localhost:9222");
// Per-test: const page = await client.page("bench");
// Teardown: await client.disconnect();
// Key difference: add `await waitForPageLoad(page)` after every goto()
// Extract types: (trs: Element[]) => trs.slice(0,5).map(tr => tr.textContent?.trim() ?? '')
```

### agent-browser

```bash
#!/bin/bash
# CLI-based — each operation is a separate command
# Setup: (none — daemon auto-starts)
# Teardown: agent-browser close

# navigate:
agent-browser open "https://the-internet.herokuapp.com/"
agent-browser screenshot /tmp/bench-ab-nav.png

# formFill:
agent-browser open "https://the-internet.herokuapp.com/login"
agent-browser snapshot -i
agent-browser fill '@username' 'tomsmith'
agent-browser fill '@password' 'SuperSecretPassword!'
agent-browser click '@submit'
agent-browser wait --url '**/secure'

# extract:
agent-browser open "https://the-internet.herokuapp.com/challenging_dom"
agent-browser eval "JSON.stringify([...document.querySelectorAll('table tbody tr')].slice(0,5).map(r=>r.textContent.trim()))"

# multiStep:
agent-browser open "https://the-internet.herokuapp.com/"
agent-browser click 'a[href="/abtest"]'
agent-browser wait --url '**/abtest'
agent-browser get url

# Timing: use python3 -c 'import time; print(time.time())' for start/end
```

### Crawl4AI

```python
# ~/.aidevops/.agent-workspace/work/browser-bench/bench-crawl4ai.py
# Run: source ~/.aidevops/crawl4ai-venv/bin/activate && python bench-crawl4ai.py
# Limitation: navigate + extract only (no form fill or multi-step)
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig
from crawl4ai.extraction_strategy import JsonCssExtractionStrategy

# Setup: BROWSER_CONFIG = BrowserConfig(headless=True)
# Context: async with AsyncWebCrawler(config=BROWSER_CONFIG) as crawler:

# navigate:
#   result = await crawler.arun(url=URL, config=CrawlerRunConfig(screenshot=True))
#   assert result.success, f"Failed: {result.error_message}"

# extract — CSS-based schema extraction:
#   schema = {"name": "TableRows", "baseSelector": "table tbody tr",
#             "fields": [{"name": "text", "selector": "td:first-child", "type": "text"}]}
#   result = await crawler.arun(url=URL,
#       config=CrawlerRunConfig(extraction_strategy=JsonCssExtractionStrategy(schema)))
#   data = json.loads(result.extracted_content)
```

### Stagehand

```javascript
// ~/.aidevops/.agent-workspace/work/browser-bench/bench-stagehand.mjs
// Key difference: uses natural-language act() and structured extract()
import { Stagehand } from "@browserbasehq/stagehand";
import { z } from "zod";

// Setup per run: const sh = new Stagehand({ env: "LOCAL", headless: true, verbose: 0 }); await sh.init();
// Page access: const page = sh.ctx.pages()[0];
// Teardown: await sh.close();

// formFill — natural language instead of selectors:
//   await sh.act("fill the username field with tomsmith");
//   await sh.act("fill the password field with SuperSecretPassword!");
//   await sh.act("click the Login button");

// extract — structured schema:
//   const data = await sh.extract("extract the first 5 rows from the table",
//     z.object({ rows: z.array(z.object({ text: z.string() })) }));

// multiStep:
//   await sh.act("click the A/B Testing link");
//   await page.waitForURL('**/abtest');
```

## Running the Full Suite

```bash
# 1. Check prerequisites
bash bench-prereqs.sh

# 2. Run each tool
cd ~/.aidevops/.agent-workspace/work/browser-bench/
node bench-playwright.mjs | tee results-playwright.json
cd ~/.aidevops/dev-browser/skills/dev-browser && bun x tsx bench.ts | tee ~/results-dev-browser.json
bash bench-agent-browser.sh | tee results-agent-browser.txt
source ~/.aidevops/crawl4ai-venv/bin/activate && python bench-crawl4ai.py | tee results-crawl4ai.json
OPENAI_API_KEY=... node bench-stagehand.mjs | tee results-stagehand.json

# 3. Compile results table
echo "Done. Compare results and update browser-automation.md benchmarks table."
```

## Parallel Instance Benchmarks

Test concurrent page/session handling per tool.

### Playwright (reference)

```javascript
// bench-parallel.mjs — tests 3 isolation levels
import { chromium } from 'playwright';

async function benchParallel() {
  const results = {};

  // Multiple contexts (same browser, cookie-isolated)
  let start = performance.now();
  const browser = await chromium.launch({ headless: true });
  const contexts = await Promise.all(Array.from({ length: 5 }, () => browser.newContext()));
  await Promise.all(contexts.map(async ctx => {
    const page = await ctx.newPage();
    await page.goto('https://the-internet.herokuapp.com/login');
  }));
  results.multiContext = `${((performance.now() - start) / 1000).toFixed(2)}s (5 contexts)`;
  await browser.close();

  // Multiple browsers (full OS-level isolation)
  start = performance.now();
  const browsers = await Promise.all(Array.from({ length: 3 }, () => chromium.launch({ headless: true })));
  await Promise.all(browsers.map(async b => {
    const page = await b.newPage();
    await page.goto('https://the-internet.herokuapp.com/');
  }));
  results.multiBrowser = `${((performance.now() - start) / 1000).toFixed(2)}s (3 browsers)`;
  await Promise.all(browsers.map(b => b.close()));

  // 10 parallel pages (shared context)
  start = performance.now();
  const b2 = await chromium.launch({ headless: true });
  const ctx = await b2.newContext();
  await Promise.all(Array.from({ length: 10 }, async () => {
    const p = await ctx.newPage();
    await p.goto('https://the-internet.herokuapp.com/');
  }));
  results.multiPage = `${((performance.now() - start) / 1000).toFixed(2)}s (10 pages)`;
  await b2.close();

  console.log(JSON.stringify(results, null, 2));
}
benchParallel();
```

### agent-browser

```bash
# bench-parallel-ab.sh — 3 parallel sessions
set -euo pipefail
start=$(python3 -c 'import time; print(time.time())')
agent-browser --session s1 open "https://the-internet.herokuapp.com/login" &
agent-browser --session s2 open "https://the-internet.herokuapp.com/checkboxes" &
agent-browser --session s3 open "https://the-internet.herokuapp.com/dropdown" &
wait
end=$(python3 -c 'import time; print(time.time())')
echo "3 parallel sessions: $(python3 -c "print(f'{$end - $start:.2f}')")s"
echo "s1: $(agent-browser --session s1 get url)"
echo "s2: $(agent-browser --session s2 get url)"
echo "s3: $(agent-browser --session s3 get url)"
agent-browser --session s1 close; agent-browser --session s2 close; agent-browser --session s3 close
```

### Crawl4AI

```python
# bench-parallel-crawl4ai.py — sequential vs arun_many()
# Key API: crawler.arun_many(urls=URLS, config=run_config) for parallel crawling
# Compare sequential (for loop with arun()) vs parallel (arun_many())
# Test URLs: /login, /checkboxes, /dropdown, /tables, /frames
# Output: "Sequential: Xs | Parallel: Ys | Speedup: Nx"
```

## Visual Verification Benchmark

Tests the screenshot + AI analysis workflow: navigate -> viewport screenshot -> ARIA snapshot -> AI analyses both -> decide next action.

```javascript
// bench-visual.mjs — extends Playwright reference with ARIA + vision metrics
// Test pages: /login (form), /tables (data table), /checkboxes (checkboxes)
// Per page: goto() -> waitForLoadState('networkidle') -> screenshot + ARIA snapshot
// WARNING: Do NOT use fullPage: true for AI vision — can exceed 8000px, crashing the session

const page = await browser.newPage();
await page.goto(url);
await page.waitForLoadState('networkidle');
await page.screenshot({ path: screenshotPath });           // viewport only
const ariaSnapshot = await page.accessibility.snapshot();   // structured DOM
const textContent = await page.evaluate(() => document.body.innerText.substring(0, 500));

// Collected metrics per page:
// { url, elapsed, screenshotSize (KB), ariaNodes, textPreview }
```

**Key metrics**: screenshot file size (token cost), ARIA node count, time to screenshot-ready, whether ARIA alone suffices vs needing vision.

## Results: Interpreting and Documenting

After running benchmarks, update the Performance Benchmarks table in `browser-automation.md`: take median of 3 runs per test, bold the fastest time per row, update the "Key insight" section if relative performance changed, and note the date/environment.

```bash
echo "Date: $(date +%Y-%m-%d) | macOS: $(sw_vers -productVersion) | Node: $(node --version) | Bun: $(bun --version 2>/dev/null || echo N/A) | Python: $(python3 --version)"
echo "Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Apple Silicon')"
```

**Interpretation notes:**

- **Cold start**: First agent-browser run is slower (daemon startup) — discard or note separately
- **Network variance**: Times vary ~0.2-0.5s — use median of 3
- **Stagehand API latency**: Depends on OpenAI/Anthropic response time — note model used
- **Crawl4AI**: Cannot do form fill or multi-step (extraction only)
- **Playwriter**: Requires manual extension activation — may skip in automated runs

## Adding New Tools

1. Add a benchmark script following the patterns above
2. Add the tool to the prerequisites check
3. Run the full suite including the new tool
4. Update `browser-automation.md` tables (Performance, Feature Matrix, Parallel, Extensions)
5. Update this file's test methods table
6. Test parallel capabilities, extension support, and visual verification
