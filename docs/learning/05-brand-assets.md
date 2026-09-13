# Subscription brand-asset manifest

Phase 5 intentionally bundles no third-party brand logo files. The repository
does not currently have a verified, reusable official asset source for the
catalog services, so every catalog entry uses the local `SubscriptionLogo`
fallback: a rounded, category-coloured surface with an accessible initial or
category icon.

| Service | Asset filename | Source URL | Retrieval date | Note |
| --- | --- | --- | --- | --- |
| Catalog services | None | None | 2026-09-13 | No unverified or runtime-downloaded logo assets are included. |

This is deliberate: the app never hotlinks remote images and does not redraw
or materially alter trademarks. When a verified official or clearly reusable
asset is later approved, add its local file, source URL, retrieval date, and
usage note here, then update the centralized resolver in
`lib/features/subscriptions/presentation/subscription_editor_sheet.dart`.
