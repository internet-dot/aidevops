# Media Controls & Data Channels

## Bandwidth Management

```ts
const s = pc.getSenders().find(s => s.track?.kind === 'video');
const p = s.getParameters();
if (!p.encodings) p.encodings = [{}];
p.encodings[0].maxBitrate = 1200000; p.encodings[0].maxFramerate = 24;
await s.setParameters(p);
```

## Simulcast

Cloudflare auto-forwards the best layer:

```ts
pc.addTransceiver('video', {direction: 'sendonly', sendEncodings: [
  {rid: 'high', maxBitrate: 1200000},
  {rid: 'med', maxBitrate: 600000, scaleResolutionDownBy: 2},
  {rid: 'low', maxBitrate: 200000, scaleResolutionDownBy: 4}
]});
```

## DataChannel

```ts
const dc = pc.createDataChannel('chat', {ordered: true, maxRetransmits: 3});
dc.onopen = () => dc.send(JSON.stringify({type: 'chat', text: 'Hi'}));
dc.onmessage = (e) => console.log('RX:', JSON.parse(e.data));
```
