# Cohere Design: Typography Rules

## Font Families

- **Display**: `CohereText`, fallbacks: `Space Grotesk, Inter, ui-sans-serif, system-ui`
- **Body / UI**: `Unica77 Cohere Web`, fallbacks: `Inter, Arial, ui-sans-serif, system-ui`
- **Code**: `CohereMono`, fallbacks: `Arial, ui-sans-serif, system-ui`
- **Icons**: `CohereIconDefault` (custom icon font)

## Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display / Hero | CohereText | 72px (4.5rem) | 400 | 1.00 (tight) | -1.44px | Maximum impact, serif authority |
| Display Secondary | CohereText | 60px (3.75rem) | 400 | 1.00 (tight) | -1.2px | Large section headings |
| Section Heading | Unica77 | 48px (3rem) | 400 | 1.20 (tight) | -0.48px | Feature section titles |
| Sub-heading | Unica77 | 32px (2rem) | 400 | 1.20 (tight) | -0.32px | Card headings, feature names |
| Feature Title | Unica77 | 24px (1.5rem) | 400 | 1.30 | normal | Smaller section titles |
| Body Large | Unica77 | 18px (1.13rem) | 400 | 1.40 | normal | Intro paragraphs |
| Body / Button | Unica77 | 16px (1rem) | 400 | 1.50 | normal | Standard body, button text |
| Button Medium | Unica77 | 14px (0.88rem) | 500 | 1.71 (relaxed) | normal | Smaller buttons, emphasized labels |
| Caption | Unica77 | 14px (0.88rem) | 400 | 1.40 | normal | Metadata, descriptions |
| Uppercase Label | Unica77 / CohereMono | 14px (0.88rem) | 400 | 1.40 | 0.28px | Uppercase section labels |
| Small | Unica77 | 12px (0.75rem) | 400 | 1.40 | normal | Smallest text, footer links |
| Code Micro | CohereMono | 8px (0.5rem) | 400 | 1.40 | 0.16px | Tiny uppercase code labels |

## Principles

- **Serif for declaration, sans for utility**: CohereText carries the brand voice at display scale — its serif terminals give headlines the authority of published research. Unica77 handles everything functional with Swiss-geometric neutrality.
- **Negative tracking at scale**: CohereText uses -1.2px to -1.44px letter-spacing at 60–72px, creating dense, impactful text blocks.
- **Single body weight**: Nearly all Unica77 usage is weight 400. Weight 500 appears only for small button emphasis. The system relies on size and spacing, not weight contrast.
- **Uppercase code labels**: CohereMono uses uppercase with positive letter-spacing (0.16–0.28px) for technical tags and section markers.
