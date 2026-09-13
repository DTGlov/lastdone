# Subscription brand-asset manifest

Subscription marks are supplied locally by the `simple_icons` Flutter package;
the app never requests an image at runtime. The centralized resolver maps
stable catalog IDs to marks where Simple Icons provides one. Unmapped services
and custom subscriptions use the intentional rounded, category-coloured
fallback with an accessible initial or category icon.

| Service | Asset filename | Source URL | Retrieval date | Note |
| --- | --- | --- | --- | --- |
| Mapped catalog services | Package glyphs | https://pub.dev/packages/simple_icons | 2026-09-13 | Simple Icons marks are used as provided by the package; trademark rights remain with their respective owners. |
| Unmapped/custom services | None | None | 2026-09-13 | No unverified or runtime-downloaded logo assets are included. |

This is deliberate: the app never hotlinks remote images and does not redraw
or materially alter trademarks and does not imply partnership or endorsement.
When a verified official or clearly reusable raster asset is later approved,
add its local file, source URL, retrieval date, and usage note here, then update the resolver in
`lib/features/subscriptions/presentation/subscription_editor_sheet.dart`.
