# Cohere Design: Responsive Behavior

## Breakpoints

| Name | Width | Key Changes |
|------|-------|-------------|
| Small Mobile | <425px | Compact layout, minimal spacing |
| Mobile | 425–640px | Single column, stacked cards |
| Large Mobile | 640–768px | Minor spacing adjustments |
| Tablet | 768–1024px | 2-column grids begin |
| Desktop | 1024–1440px | Full multi-column layout |
| Large Desktop | 1440–2560px | Maximum container width |

*26 breakpoints detected — one of the most granularly responsive sites in the dataset.*

## Touch Targets

- Buttons adequately sized for touch interaction
- Navigation links with comfortable spacing
- Card surfaces as touch targets

## Collapsing Strategy

- **Navigation**: Full nav collapses to hamburger
- **Feature grids**: Multi-column → 2-column → single column
- **Hero text**: 72px → 48px → 32px progressive scaling
- **Purple sections**: Maintain full-width, content stacks
- **Card grids**: 3 → 2 → 1 column

## Image Behavior

- Photography scales proportionally within 22px-radius containers
- Product screenshots maintain aspect ratio
- Purple sections scale background proportionally
