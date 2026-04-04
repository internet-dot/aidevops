# Cohere Design: Layout Principles

## Spacing System

- Base unit: 8px
- Scale: 2px, 6px, 8px, 10px, 12px, 16px, 20px, 22px, 24px, 28px, 32px, 36px, 40px, 56px, 60px
- Button padding varies by variant
- Card internal padding: approximately 24–32px
- Section vertical spacing: generous (56–60px between sections)

## Grid & Container

- Max container width: up to 2560px (very wide) with responsive scaling
- Hero: centered with dramatic typography
- Feature sections: multi-column card grids
- Enterprise sections: full-width purple bands
- 26 breakpoints detected — extremely granular responsive system

## Whitespace Philosophy

- **Enterprise clarity**: Each section presents one clear proposition with breathing room between.
- **Photography as hero**: Large photographic sections provide visual interest without requiring decorative design elements.
- **Card grouping**: Related content is grouped into 22px-rounded cards, creating natural information clusters.

## Border Radius Scale

| Name | Value | Use |
|------|-------|-----|
| Sharp | 4px | Navigation elements, small tags, pagination |
| Comfortable | 8px | Dialog boxes, secondary containers, small cards |
| Generous | 16px | Featured containers, medium cards |
| Large | 20px | Large feature cards |
| Signature | 22px | Primary cards, hero images, main containers — THE Cohere radius |
| Pill | 9999px | Buttons, tags, status indicators |
