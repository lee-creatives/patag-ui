# PATAG design system

Updated 23 October 2026. Applies to the existing LGU, maintenance and Flutter citizen applications, plus their portable browser companion.

## Identity and typography

Preserve the official PATAG wordmark and cone mascot. Ink Navy #182B49 and Tangerine #F26A32 remain brand anchors. All interface typography uses locally bundled Montserrat, with its SIL Open Font License beside the font. The wordmark artwork is unchanged. Headings use 600 weight and close tracking; body uses 400–500; data uses tabular numerals. Web page titles scale 28–38px, section titles 17–20px, body 14–16px, and supporting labels 11–13px. Native headline sizes are 28–34px and scale with accessibility preferences.

## Color roles

| Role | Light | Dark |
| --- | --- | --- |
| Ground | #F7F1EB | #101114 |
| Surface | #FFFFFF | #1B1C20 |
| Raised/control | #F0EBE5 | #26272C |
| Primary text | #171717 | #F8F8F8 |
| Supporting text | #626263 | #B5B5BE |
| Border | #E5DFD8 | #35363B |

Primary actions use a 135-degree #FFAA76 → #FF7A2F → #F26A32 gradient with dark text. Feature surfaces use #333438 → #111215 with light text. Use neutral actions for secondary tasks. Status chips retain paired pale fills and dark labels, plus readable status words.

## Composition and components

- Desktop web: 260px grouped sidebar or 76px collapsed rail; fluid content, 28px gutters and a 12-column grid with 20px gaps. The sidebar pushes content instead of covering it. Below 1024px it becomes a dismissible keyboard-accessible drawer.
- Cards: 22–24px main surfaces, 16px nested maps and 14–16px controls. One feature metric leads; operational work, road locations, trends and priorities retain their actual computed data. Subtle two-layer shadows separate light surfaces.
- Controls: 44px web targets, visible focus, restrained hover/pressed feedback. Native main actions are at least 52px tall. Orange gradients are reserved for primary actions and selected feature areas.
- Glass: top navigation and selected overlays only, with solid fallbacks; no transparent data panels.
- Maps: isolated layer 1, sticky chrome 20, scrim 30, drawer 40, toasts 60. Web modal dialogs use the browser top layer. ResizeObserver refreshes Leaflet layout. Dark styling affects tiles without inverting pins or overlays.
- Tables: contained horizontal scrolling; forms and evidence panels use min-width:0 and responsive grid tracks. Charts resize inside their container.
- Native: a greeting/avatar row, orange report feature, dark impact summary, rounded dark navigation with SafeArea; the keyboard does not cover the wizard action area.

## Theme state

React theme.ts applies `data-theme`, follows system preference until chosen, and persists `patag-theme` in localStorage. CSS variables cover the shared screens and charts. Flutter ThemeController stores ThemeMode through shared_preferences; MaterialApp supplies centralized light/dark ThemeData and animates the transition. Settings can restore system mode. Both native and web navigation expose the toggle.

## Implementation and verification

Web source: each portal's `src/theme.ts` and `src/styles/visual-system.css`, layered after existing layout styles. Native source: `citizen-mobile/lib/app/theme.dart` and `lib/shared/widgets/ui.dart`. Browser companion: `browser-preview/citizen-premium.css` and `citizen.mjs`.

See [validation and evidence](visual-system/validation.md). The applications retain the existing fictional demo data and backend contracts. No new real-world claims, partnerships or metrics were introduced.
