# Phase 9: Release stabilization

This phase fixes the small lifecycle and date-model defects found during manual
testing and adds a Social category to the subscription catalog.

## Fixes

- The completion Undo SnackBar is owned by the stateful Today screen. Its
  explicit five-second timer is cancelled when Undo is pressed, when a newer
  completion replaces it, and when the screen is disposed. Expiry only hides
  the SnackBar; it never deletes the completion.
- The You page applies only the top `SafeArea` inset locally. The shell remains
  responsible for the bottom navigation inset.
- `AppPreferencesController` is now created and disposed by the app-level
  `ChangeNotifierProvider`. The display-name sheet owns only its text field and
  keeps itself open while a save fails.
- A scheduled tracker can have an optional `firstDueDate` before its first
  real completion. It is distinct from “last completed”: it never creates a
  completion row. `TodayClassifier` and reminder scheduling use it until the
  tracker has genuine completion history.
- The celebration card uses a dark-mode-safe raised surface and a semantic
  completion border instead of relying on a bright green fill.

## First due date migration

Database version 5 adds nullable `trackers.first_due_date` with a forward-only
`ALTER TABLE` migration. Existing trackers and completions remain unchanged.
After the first completion, the existing cadence calculation remains the sole
source of the next due date. The existing reminder coordinator uses the first
due date only when no completion exists.

## Social subscriptions

The code-owned catalog now includes X Premium, LinkedIn Premium, Snapchat+,
Meta Verified, Discord Nitro, Telegram Premium, Reddit Premium, and Patreon.
Stable catalog IDs preserve the distinction between a catalog suggestion and a
user-edited display name. Simple Icons are used where the installed package
exposes a supported mark; LinkedIn currently uses the existing intentional
fallback because no matching mark is exposed by that package version.

## Manual release checks

Exercise the completion SnackBar and Undo lifecycle, repeat display-name saves,
safe-area layout, future first-due dates, reminder recalculation, dark and
light celebration surfaces, and all Social catalog create/edit flows. Relaunch
after each persistence check and confirm existing trackers, completions,
reminders, and subscriptions remain intact.

Remaining release risks are platform-specific notification behavior and the
absence of automated regression coverage, which are intentionally governed by
the project validation policy.

## Phase 9 addendum

The timezone crash occurred because initialization could race between gateway
callers and the fallback attempted `getLocation('UTC')`, even though that name
was not registered by the selected timezone data. `LocalNotificationGateway`
now memoizes one initialization future, loads `latest_all`, resolves the
device's IANA identifier after loading, and falls back to the package's
initialized `tz.UTC` object. Notification startup remains isolated from app
startup and persistence; callers surface friendly recovery UI when permission
or scheduling setup fails.

`LastDoneDialog` is the shared visual shell for information, success, warning,
error, confirmation, and destructive-confirmation variants. It uses a custom
rounded Material `Dialog` surface with semantic borders, scrollable content,
accessible actions, and light/dark theme tokens. Field validation remains
inline; recoverable save, permission, and discard decisions use the shared
dialog instead of the stock `AlertDialog` appearance.

`LastDoneCalendar` wraps `table_calendar` version 3.2.1. It owns its focused
month while open and supplies field-specific bounds: historical completion is
limited to today and earlier, first due dates begin today and can extend into
the future, and subscription charge dates retain their existing editable
range. The calendar is presentation only; ViewModels still validate submitted
dates.

The Flutter startup handoff now remains visible for about 2.3 seconds in normal
motion and 700 milliseconds with reduced motion. Initialization continues
concurrently underneath it, and the existing onboarding and notification
routing guards remain responsible for the destination.

## Timeline stabilization

The reported `_debugRelayoutBoundary` assertion occurred while the Timeline
filter rebuild and a concurrent refresh were competing to replace the visible
feed. The ViewModel now models `All` as an explicit
`TimelineCategoryFilter.all` value, resets its pagination state when the filter
changes, and serializes refreshes by generation. A late page cannot replace a
newer filter result, and the active request always clears its loading state
before a queued request begins. Re-selecting `All` is a no-op, so it cannot
trigger a redundant layout refresh.

Timeline continues to query only joined persisted `completions` rows. The
unfiltered query leaves the category predicate out entirely, empty search text
adds no SQL filter, and keyset pagination starts with a null cursor and orders
by completion timestamp then stable completion ID. Trackers without completion
history therefore remain absent from Timeline; they belong on Today. The
unfiltered empty state and the filtered-empty state now explain that
distinction separately from an initial query error.

## Timeline rendering follow-up

The first reported stack excerpt contained only Flutter framework frames, so it
did not provide a LastDone-owned source location. Source tracing identified the
concrete re-entry path: the Timeline scroll notification called `loadMore()`
synchronously while the viewport was laying out, and that method called
`notifyListeners()`. The resulting rebuild could request layout again; the
later `RenderAnimatedOpacity was not laid out` message was a consequence of
that interrupted layout. The Timeline also used an `AnimatedSwitcher` to swap
independently sized loading, empty, error, and feed trees, increasing the
surface area of the failure.

Timeline now renders all states as ordinary conditional children inside one
page-level `ListView`; no Timeline `AnimatedSwitcher` or opacity transition
remains. Pagination requests are coalesced and scheduled after the current
frame, with disposal and request-generation guards. Filter changes use the
explicit All state and replace immutable result lists. The joined SQLite query
was not filtering out completions: missing visibility was a ViewModel
refresh/layout lifecycle problem, not a migration or synthetic-data problem.
Trackers without completions remain intentionally absent from the history feed.
