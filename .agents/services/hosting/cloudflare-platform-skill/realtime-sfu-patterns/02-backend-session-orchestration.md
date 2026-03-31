# Backend Session Orchestration

## Express

```js
app.post('/api/new-session', async (req, res) => {
  const r = await fetch(`${CALLS_API}/apps/${process.env.CALLS_APP_ID}/sessions/new`,
    {method: 'POST', headers: {'Authorization': `Bearer ${process.env.CALLS_APP_SECRET}`}});
  res.json(await r.json());
});
```

## Workers

```ts
export default {
  async fetch(req: Request, env: Env) {
    return fetch(`https://rtc.live/v1/apps/${env.CALLS_APP_ID}/sessions/new`,
      {method: 'POST', headers: {'Authorization': `Bearer ${env.CALLS_APP_SECRET}`}});
  }
};
```

## Durable Objects Presence

```ts
export class Room {
  sessions = new Map(); // sessionId -> {userId, tracks: [{trackName, kind}]}

  async fetch(req: Request) {
    const {pathname} = new URL(req.url);
    if (pathname === '/join') {
      const {sessionId, userId} = await req.json();
      this.sessions.set(sessionId, {userId, tracks: []});
      const existingTracks = Array.from(this.sessions.entries())
        .filter(([id]) => id !== sessionId)
        .flatMap(([id, data]) => data.tracks.map(t => ({...t, sessionId: id})));
      return Response.json({existingTracks});
    }
    if (pathname === '/publish') {
      const {sessionId, tracks} = await req.json();
      this.sessions.get(sessionId)?.tracks.push(...tracks); // Notify others via WS
      return new Response('OK');
    }
  }
}
```
