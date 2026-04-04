# Design System: Cohere

Polished enterprise command deck. Bright white canvas, 22px signature card radius, dual custom typeface (CohereText serif + Unica77 sans), near-monochrome palette with deep purple hero bands.

## Chapters

| # | File | Contents |
|---|------|----------|
| 1 | [01-visual-theme.md](01-visual-theme.md) | Visual theme, atmosphere, key characteristics |
| 2 | [02-color-palette.md](02-color-palette.md) | Full color palette, roles, gradient system |
| 3 | [03-typography.md](03-typography.md) | Font families, hierarchy table, principles |
| 4 | [04-components.md](04-components.md) | Buttons, cards, inputs, nav, images, distinctive components |
| 5 | [05-layout.md](05-layout.md) | Spacing system, grid, whitespace, border radius scale |
| 6 | [06-depth-elevation.md](06-depth-elevation.md) | Elevation levels, shadow philosophy |
| 7 | [07-dos-donts.md](07-dos-donts.md) | Do's and Don'ts reference |
| 8 | [08-responsive.md](08-responsive.md) | Breakpoints, touch targets, collapsing strategy, image behavior |
| 9 | [09-agent-prompts.md](09-agent-prompts.md) | Quick color reference, example prompts, iteration guide |

## Quick Reference

**Palette essentials:**

- Background: `#ffffff` (Pure White)
- Primary text: `#000000` (Cohere Black)
- Secondary text: `#212121` (Near Black)
- Muted text: `#93939f` (Muted Slate)
- Interactive accent: `#1863dc` (Interaction Blue — hover/focus only)
- Card border: `#f2f2f2` (Lightest Gray)
- Section border: `#d9d9dd` (Border Cool)

**Typography essentials:**

- Display: `CohereText` (custom serif), weight 400, negative tracking at scale
- Body/UI: `Unica77 Cohere Web` (geometric sans), weight 400
- Code/labels: `CohereMono`, uppercase with positive letter-spacing

**Signature patterns:**

- Border radius: 22px for all primary cards and containers (the Cohere signature)
- Buttons: ghost/transparent by default; text shifts to `#1863dc` on hover
- Depth via color contrast (white-on-purple), not shadows
- Purple reserved for full-width hero bands only — never card backgrounds
