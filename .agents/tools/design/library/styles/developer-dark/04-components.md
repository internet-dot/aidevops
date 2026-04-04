# Design System: Developer Dark — Component Stylings

## Buttons

**Primary (Green):** bg `#4ade80`, text `#111827` (dark on green for contrast), radius 4px, padding 8px 16px, JetBrains Mono 13px weight 600 uppercase letter-spacing 0.5px. Hover `#22c55e`, active `#16a34a`, focus outline `2px solid #4ade80` offset `2px`, disabled opacity 0.4 cursor not-allowed.

**Secondary (Ghost):** bg transparent, text `#f9fafb`, border `1px solid #374151`, radius 4px, padding 8px 16px. Hover bg `#1f2937` border `#4b5563`, focus outline `2px solid #4ade80` offset `2px`.

**Danger:** bg `#ef4444`, text `#ffffff`, radius 4px. Hover `#dc2626`.

## Inputs

**Text Input:** bg `#0d1117`, text `#f9fafb`, border `1px solid #374151`, radius 4px, padding 8px 12px, JetBrains Mono 14px weight 400, placeholder `#6b7280`. Focus border `#4ade80` shadow `0 0 0 2px rgba(74,222,128,0.2)`. Error border `#ef4444` shadow `0 0 0 2px rgba(239,68,68,0.2)`.

## Links

- Default: `#3b82f6`, underline (body text links — accessibility requirement; see 07-dos-donts.md)
- Hover: `#60a5fa`, underline
- Active: `#2563eb`
- Code links: `#4ade80`, hover `#22c55e`

## Cards & Containers

- Background: `#1f2937`, border `1px solid #374151`, radius 4px, padding 16px, shadow none (border-driven depth)
- Hover: border-color `#4b5563`

## Navigation

- Sticky top bar: bg `#111827`, border-bottom `1px solid #1f2937`
- Nav links: JetBrains Mono 13px weight 500, `#9ca3af`; active `#4ade80`; hover `#f9fafb`
- Logo/brand: JetBrains Mono 15px weight 700, `#f9fafb`
