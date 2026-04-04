<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: 2025-2026 Marcus Quinn -->

# Design System: Lovable — Component Stylings

## Buttons

Shared defaults (all variants unless noted): padding 8px 16px · radius 6px · active opacity 0.8 · focus `rgba(0,0,0,0.1) 0px 4px 12px` shadow

**Primary Dark (Inset Shadow)**
- Background: `#1c1c1c` · Text: `#fcfbf8`
- Shadow: `rgba(0,0,0,0) 0px 0px 0px 0px, rgba(0,0,0,0) 0px 0px 0px 0px, rgba(255,255,255,0.2) 0px 0.5px 0px 0px inset, rgba(0,0,0,0.2) 0px 0px 0px 0.5px inset, rgba(0,0,0,0.05) 0px 1px 2px 0px`
- Use: Primary CTA ("Start Building", "Get Started")

**Ghost / Outline**
- Background: transparent · Text: `#1c1c1c`
- Border: `1px solid rgba(28,28,28,0.4)`
- Use: Secondary actions ("Log In", "Documentation")

**Cream Surface**
- Background: `#f7f4ed` · Text: `#1c1c1c` · No border
- Use: Tertiary actions, toolbar buttons

**Pill / Icon Button**
- Background: `#f7f4ed` · Text: `#1c1c1c` · Radius: 9999px
- Shadow: same inset pattern as Primary Dark
- Opacity: 0.5 (default), 0.8 (active)
- Use: Additional actions, plan mode toggle, voice recording

## Cards & Containers

- Background: `#f7f4ed` · Border: `1px solid #eceae4`
- Radius: 12px (standard), 16px (featured), 8px (compact)
- No box-shadow — borders define boundaries
- Image cards: same border, 12px radius

## Inputs & Forms

- Background: `#f7f4ed` · Text: `#1c1c1c`
- Border: `1px solid #eceae4` · Radius: 6px
- Focus: ring blue (`rgba(59,130,246,0.5)`) outline
- Placeholder: `#5f5f5d`

## Navigation

- Fixed horizontal nav on cream background
- Logo/wordmark left-aligned (128.75 x 22px)
- Links: Camera Plain 14–16px weight 400, `#1c1c1c`
- CTA: Primary Dark button (6px radius)
- Mobile: hamburger menu, 6px radius button
- Subtle border or none on scroll

## Links

- Color: `#1c1c1c` · Decoration: underline (default)
- Hover: `hsl(var(--primary))` — decoration carries interactive signal, no color change

## Image Treatment

- Border: `1px solid #eceae4` · Radius: 12px on all containers
- Hero: soft gradient background (warm multi-color wash)
- Showcases: gallery-style grid presentation

## Distinctive Components

**AI Chat Input**
- Large prompt area, soft borders
- Suggestion pills: `#eceae4` borders
- Voice/plan-mode toggles: pill shape (9999px radius)

**Template Gallery**
- Card grid: image + title, `1px solid #eceae4` border, 12px radius
- Hover: subtle shadow or border darkening
- Category labels: text links

**Stats Bar**
- Metrics: "0M+" pattern, 48px+ weight 600
- Descriptor text: muted gray below
- Layout: horizontal, generous spacing
