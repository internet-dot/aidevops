# Cron Triggers Gotchas

## Time and propagation

- **UTC only** — cron triggers have no timezone setting.
- **Propagation delay** — trigger changes can take up to 15 minutes. Verify in Dashboard → Workers → Select Worker → Settings → Triggers.

```typescript
// ❌ Wrong: "0 9 * * *" // 9am UTC, not local
// ✅ Right: "0 17 * * *" // 9am PST (UTC-8) = 17:00 UTC
// Calculate: utcHour = (localHour - utcOffset + 24) % 24
```

## Limits and long-running work

| Plan | Triggers/Worker | CPU Time | Execution |
|------|----------------|----------|-----------|
| Free | 3 | 10ms | At-least-once |
| Paid | Unlimited | 50ms | At-least-once |

```typescript
// ❌ BAD: await processLargeDataset(); // May exceed CPU
// ✅ GOOD: ctx.waitUntil(processLargeDataset(env));
// ✅ OR: await env.WORKFLOW.create({});
```

## Duplicate executions

At-least-once delivery means duplicates are possible; make scheduled handlers idempotent.

```typescript
export default {
  async scheduled(controller, env, ctx) {
    const execId = `${controller.scheduledTime}-${controller.cron}`;
    if (await env.KV.get(`exec:${execId}`)) return;
    await env.KV.put(`exec:${execId}`, "processing", { expirationTtl: 3600 });
    await performTask(env);
    await env.KV.put(`exec:${execId}`, "complete", { expirationTtl: 86400 });
  },
};
```

## Not executing

Check: `scheduled()` exported, recent deploy, 15-minute wait elapsed, valid cron ([crontab.guru](https://crontab.guru/)), and plan limits.

```typescript
export default {
  async scheduled(controller, env, ctx) {
    console.log("EXECUTED", {time: new Date().toISOString(), scheduledTime: new Date(controller.scheduledTime).toISOString(), cron: controller.cron});
    ctx.waitUntil(env.KV.put("last_execution", Date.now().toString()));
  },
};
```

## Execution failures

Common causes: CPU exceeded, unhandled exceptions, network timeouts, and binding misconfiguration.

```typescript
export default {
  async scheduled(controller, env, ctx) {
    try {
      const abortCtrl = new AbortController();
      const timeout = setTimeout(() => abortCtrl.abort(), 5000);
      const response = await fetch("https://api.example.com/data", {signal: abortCtrl.signal});
      clearTimeout(timeout);
      if (!response.ok) throw new Error(`API: ${response.status}`);
      await processData(await response.json(), env);
    } catch (error) {
      console.error("Failed", {error: error.message, cron: controller.cron});
      // Don't re-throw to mark success despite errors
    }
  },
};
```

## Local testing

- Ensure `wrangler dev` runs.
- Ensure `scheduled()` exists.
- Update Wrangler if needed: `npm i -g wrangler@latest`.

```bash
curl "http://localhost:8787/__scheduled?cron=*/5+*+*+*+*" # URL encode spaces
curl "http://localhost:8787/__scheduled" # No params = default
# Python: curl "http://localhost:8787/cdn-cgi/handler/scheduled?cron=*/5+*+*+*+*"
```

## Dev-only trigger endpoint

```typescript
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === "/__scheduled") {
      if (env.ENVIRONMENT === "production") return new Response("Not found", { status: 404 });
      await this.scheduled({scheduledTime: Date.now(), cron: url.searchParams.get("cron") || "* * * * *", type: "scheduled"}, env, ctx);
      return new Response("OK");
    }
    return new Response("Hello");
  },
  async scheduled(controller, env, ctx) {},
};
```

## Secrets management

```typescript
// ❌ BAD: headers: { "Authorization": "Bearer sk_live_abc123..." }
// ✅ GOOD: headers: { "Authorization": `Bearer ${env.API_KEY}` }
```

```bash
npx wrangler secret put API_KEY
```

## Green Compute

Dashboard: Workers & Pages → Account details → Compute Setting → Green Compute. Tradeoffs: fewer locations, higher latency, ideal for non-time-critical jobs.

## Resources

- [Cron Triggers Docs](https://developers.cloudflare.com/workers/configuration/cron-triggers/)
- [Scheduled Handler API](https://developers.cloudflare.com/workers/runtime-apis/handlers/scheduled/)
- [Cloudflare Workflows](https://developers.cloudflare.com/workflows/)
- [Workers Limits](https://developers.cloudflare.com/workers/platform/limits/)
- [Crontab Guru](https://crontab.guru/) - Validator
