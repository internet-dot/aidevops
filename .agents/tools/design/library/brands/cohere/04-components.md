# Cohere Design: Component Stylings

## Buttons

### Ghost / Transparent

- Background: transparent (`rgba(255, 255, 255, 0)`)
- Text: Cohere Black (`#000000`)
- No border visible
- Hover: text shifts to Interaction Blue (`#1863dc`), opacity 0.8
- Focus: solid 2px outline in Interaction Blue
- The primary button style — invisible until interacted with

### Dark Solid

- Background: dark/black
- Text: Pure White
- For CTA on light surfaces
- Pill-shaped or standard radius

### Outlined

- Border-based containment
- Used in secondary actions

## Cards & Containers

- Background: Pure White (`#ffffff`)
- Border: thin solid Lightest Gray (`1px solid #f2f2f2`) for subtle cards; Cool Border (`#d9d9dd`) for emphasized
- Radius: **22px** — the signature Cohere radius for primary cards, images, and dialog containers. Also 4px, 8px, 16px, 20px for smaller elements
- Shadow: minimal — Cohere relies on background color and borders rather than shadows
- Special: `0px 0px 22px 22px` radius (bottom-only rounding) for section containers
- Dialog: 8px radius for modal/dialog boxes

## Inputs & Forms

- Text: white on dark input, black on light
- Focus border: Focus Purple (`#9b60aa`) with `1px solid`
- Focus shadow: red ring (`rgb(179, 0, 0) 0px 0px 0px 2px`) — likely for error state indication
- Focus outline: Interaction Blue solid 2px

## Navigation

- Clean horizontal nav on white or dark background
- Logo: Cohere wordmark (custom SVG)
- Links: Dark text at 16px Unica77
- CTA: Dark solid button
- Mobile: hamburger collapse

## Image Treatment

- Enterprise photography with diverse subjects and environments
- Purple-tinted hero photography for dramatic sections
- Product UI screenshots on dark surfaces
- Images with 22px radius matching card system
- Full-bleed purple gradient sections

## Distinctive Components

### 22px Card System

- The 22px border-radius is Cohere's visual signature
- All primary cards, images, and containers use this radius
- Creates a cloud-like, organic softness that's distinctive from the typical 8–12px

### Enterprise Trust Bar

- Company logos displayed in a horizontal strip
- Demonstrates enterprise adoption
- Clean, monochrome logo treatment

### Purple Hero Bands

- Full-width deep purple sections housing product showcases
- Create dramatic visual breaks in the white page flow
- Product screenshots float within the purple environment

### Uppercase Code Tags

- CohereMono in uppercase with letter-spacing
- Used as section markers and categorization labels
- Creates a technical, structured information hierarchy
