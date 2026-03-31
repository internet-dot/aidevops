---
description: App Store and Play Store publishing - submission, compliance, screenshots, metadata, rejection handling
mode: subagent
tools:
  read: true
  write: true
  edit: true
  bash: true
  glob: true
  grep: true
  webfetch: true
  task: true
---

# App Publishing - Store Submission and Compliance

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Apple**: $99/year — https://developer.apple.com/programs/ (24-48h activation)
- **Google**: $25 one-time — https://play.google.com/console/ (minutes to days)
- **Common rejections**: Missing privacy policy, placeholder content, broken features, guideline violations
- **CLI**: `asc` — see `tools/mobile/app-store-connect.md` for programmatic ASC management

<!-- AI-CONTEXT-END -->

## CLI Automation — asc

```bash
brew install tddworks/tap/asccli
asc auth login --key-id KEY --issuer-id ISSUER --private-key-path ~/.asc/AuthKey.p8
asc apps list
```

Use `asc` for App Store Connect operations; the checklists below cover submission compliance.

## Apple App Store

### Pre-Submission Checklist

- [ ] Active Apple Developer Program membership
- [ ] App builds and runs without crashes
- [ ] Privacy policy URL (hosted, accessible)
- [ ] Terms of service URL (if applicable)
- [ ] App Store description (up to 4000 characters)
- [ ] Keywords (up to 100 characters)
- [ ] Screenshots for required device sizes
- [ ] App icon (1024x1024, no alpha channel, no rounded corners)
- [ ] Age rating questionnaire completed
- [ ] App category selected
- [ ] Support URL provided
- [ ] Contact information for review team
- [ ] Account deletion feature (accounts; required since 2022)
- [ ] Demo account credentials for review team (accounts)
- [ ] Sign in with Apple supported (accounts with third-party sign-in)
- [ ] In-app purchases configured in App Store Connect (payments)
- [ ] Subscription terms clearly displayed before purchase (payments)
- [ ] Restore purchases button accessible (payments)
- [ ] No external payment links (payments; App Store guideline 3.1.1)
- [ ] Block/report functionality (social features)
- [ ] Content moderation plan (social features)
- [ ] User-generated content guidelines (social features)

### Common Rejection Reasons

| Reason | Guideline | Fix |
|--------|-----------|-----|
| Crashes or bugs | 2.1 | Test on multiple devices |
| Placeholder content | 2.3.3 | Remove lorem ipsum, test data, "coming soon" |
| Incomplete information | 2.1 | Fill all metadata, provide demo credentials |
| Privacy violations | 5.1.1 | Add privacy policy, declare data collection accurately |
| Misleading description | 2.3.1 | Description must match actual functionality |
| No account deletion | 5.1.1 | Add in-app account deletion if accounts exist |
| External payment links | 3.1.1 | Remove links to external payment methods |
| Minimum functionality | 4.2 | App must provide lasting value beyond a simple website |

### Screenshot Requirements

| Device | Size (portrait) | Required |
|--------|-----------------|----------|
| iPhone 6.9" | 1320 x 2868 | Yes (covers 6.7" and 6.9") |
| iPhone 6.5" | 1284 x 2778 | Yes |
| iPad Pro 13" | 2064 x 2752 | If iPad supported |
| iPad Pro 12.9" | 2048 x 2732 | If iPad supported |

Tips: show the app in use, not empty states; highlight key features with captions; keep a consistent style; prioritize the first screenshot because it appears in search results; use Remotion to create animated App Store preview videos (up to 30 seconds).

### App Review Process

- **Timeline**: 24-48 hours typically, up to 7 days
- **Expedited review**: Available for critical bug fixes via App Store Connect
- **Rejection**: Fix the specific issue cited, resubmit with explanation; appeal available

## Google Play Store

### Pre-Submission Checklist

- [ ] Google Play Developer account
- [ ] Privacy policy URL
- [ ] App description (up to 4000 characters)
- [ ] Short description (up to 80 characters)
- [ ] Feature graphic (1024 x 500)
- [ ] App icon (512 x 512)
- [ ] Screenshots (minimum 2, up to 8 per device type)
- [ ] Content rating questionnaire completed
- [ ] Target audience and content declarations
- [ ] Data safety section completed
- [ ] AAB (Android App Bundle) format (not APK)
- [ ] Target API level meets current requirement
- [ ] 64-bit support
- [ ] Permissions justified and minimal

### Play Store Review

- **Timeline**: Hours to a few days
- **Policy centre**: Check for policy violations
- **Pre-launch report**: Automated testing on multiple devices — review results before release

## Metadata Optimisation (ASO)

- **App name**: Include the primary keyword naturally; ≤30 chars (Apple) / ≤50 chars (Google); prefer brand + keyword.
- **Keywords (Apple)**: 100-character limit, comma-separated, no repeats from app name, singular forms, no spaces after commas.
- **Description**: Lead with the core value proposition in the first 3 lines; use short paragraphs, bullet points, social proof, and a call to action.
- **Localisation**: Localise metadata for target markets even if the app is English-only. Localised screenshots improve conversion. Top markets: US, UK, Germany, Japan, Brazil, France.

## Related

- `tools/mobile/app-store-connect.md` — App Store Connect CLI (asc), programmatic ASC management
- `tools/mobile/app-dev/testing.md` — Pre-submission testing
- `product/monetisation.md` — Payment setup
- `tools/mobile/app-dev/assets.md` — Screenshot and icon generation
- `tools/browser/remotion-best-practices-skill.md` — Preview video creation
