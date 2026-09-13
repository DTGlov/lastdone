# EverDun rebrand

EverDun is the product name, while Dun remains the mascot’s name. The rename is a pre-release identity migration: the Dart package is `everdun`, iOS uses `com.dtglover.everdun`, and Android uses `com.dtglover.everdun`. The Git remote intentionally remains `https://github.com/DTGlov/lastdone.git` until David chooses to rename the GitHub repository. Xcode’s target remains `Runner`.

## Identity and local data

User-facing titles, onboarding, About, licenses, privacy copy, accessibility labels, notifications, and the startup wordmark use `EverDun`. Product-specific Dart symbols and design-system files use the same spelling. Neutral domain concepts such as last-completed dates are unchanged.

The SQLite filename changes from `lastdone.db` to `everdun.db`, and notification channel/resource identifiers use the new identity. A new bundle/application ID creates a separate app sandbox, so existing simulator development data does not transfer automatically. This reset is acceptable before release; the old LastDone installation may remain until manually removed.

## Branding and startup

The approved opaque Dun-face master is used for iOS and Android launcher icons. The transparent adaptive foreground is used for Android adaptive icons and the native splash configuration. Generated platform resources are produced from `assets/branding/everdun_app_icon.png` and `assets/branding/everdun_adaptive_foreground.png`. The existing full-body Dun artwork remains in-app artwork. Android keeps a separate monochrome checkmark status icon and Dun large notification artwork.

The native splash remains static and fast. The Flutter-hosted startup overlay presents Dun and the EverDun wordmark while initialization continues concurrently, preserving the longer motion and reduced-motion timings. Onboarding and notification deep-link routing remain the destination authority.

## Counts and terminology

`lib/core/text/count_text.dart` centralizes simple count grammar so one day is never displayed as “1 days”. Due, overdue, history, reminder, and subscription copy uses the same singular/plural rule where a numeric duration is shown.

## Intentional boundaries

This phase does not rewrite neutral SQLite table or column names, migrate data from another application sandbox, rename the GitHub remote, or rename the Xcode `Runner` target. Historical learning notes may mention LastDone as the former product name, but active product copy and instructions use EverDun.
