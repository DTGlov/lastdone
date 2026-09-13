# Phase 4: Completion and undo

Phase 4 adds the core completion loop. A Today card opens a dedicated tracker
detail page, where the user can inspect the tracker, see its current status and
recent history, and mark it done today. After a successful save, the detail
page briefly celebrates and returns the exact new completion to Today. Today’s
existing classifier then places the tracker in the correct mutually exclusive
section.

## Detail-page state flow

`TrackerDetailViewModel` subscribes once to the repository’s typed detail
stream. It owns loading, missing, content, saving, already-completed-today,
and recoverable-error state. The screen renders that state and keeps routing,
haptics, SnackBars, and animation in the presentation layer.

The repository returns a `TrackerDetails` projection containing the tracker
and the five newest completions. It does not expose SQLite rows. Editing still
uses the existing editor and changes tracker metadata only; it never rewrites
completion history.

## Completion persistence

`LocalTrackerRepository.completeToday` uses the timestamp supplied by the
injected `AppClock`. Inside one SQLite transaction it checks the tracker’s
completion rows after converting their timestamps to local time, and compares
them with the current local calendar-day range. If a completion already exists,
the operation returns no new completion and the detail action stays completed.
Otherwise it inserts one typed `Completion` with a stable generated ID.

The same-local-day check is intentionally a calendar comparison, not a rolling
24-hour window. This follows the app’s local-date convention and remains
correct across ordinary daylight-saving boundaries. The repository refreshes
the overview stream and the matching detail stream after insertion.

Undo receives the exact completion ID returned by that operation. It asks the
repository to delete only that ID in a transaction, then refreshes both streams.
Repeating Undo is safe because a missing ID produces no deletion. “Done again”
on the same local day is intentionally unsupported in this version.

## Celebration and reduced motion

Saved state and celebration are separate. Persistence completes first; only
then does the detail screen trigger haptics, Dun’s celebrating state, a short
custom-painted burst, and a success message. A reduced-motion setting skips
the burst and delay but keeps the same database write, semantic state, and
navigation result. Disposing the screen disposes its animation controller, and
the ViewModel guards stream callbacks after disposal.

Today receives the exact completion through the `/trackers/:id` route result.
Its SnackBar offers Undo for a short five-second window. Expiry, app
termination, and historical-completion editing remain outside this phase.

## Manual testing

1. Open a never-completed tracker from Today and inspect its status, cadence,
   and empty history.
2. Verify an editor-created initial completion appears in the preview.
3. Edit metadata and confirm history does not change.
4. Tap Done today once, observe the compact celebration, return to Today, and
   confirm the tracker moves according to the existing classifier.
5. Rapidly tap the action and reopen the detail page; confirm there is only one
   completion for the local day.
6. Use Undo from Today and confirm the previous status and history return.
7. Complete again, let the Undo window expire, relaunch, and confirm it stays
   persisted. Check a tracker already completed today cannot be completed again.
8. Repeat checks for scheduled and unscheduled trackers, light/dark mode,
   large text, compact width, scrolling, semantics, reduced motion, and
   navigating away during the celebration.

## Deferred work

Full Timeline/history management, completion editing, archive/delete/restore,
reminders, notifications, Life Rhythm scoring, cloud sync, authentication,
backend services, social sharing, and subscriptions remain deferred.

```mermaid
flowchart LR
  A[Today card] --> B[/trackers/:id]
  B --> C[Detail ViewModel]
  C --> D[SQLite same-day transaction]
  D --> E[Exact Completion ID]
  E --> F[Celebration then Today]
  F --> G[Undo exact ID]
  G --> H[Repository stream refresh]
  H --> A
```

Important references:

- `lib/features/trackers/presentation/tracker_detail_screen.dart`
- `lib/features/trackers/presentation/tracker_detail_view_model.dart`
- `lib/features/trackers/data/local_tracker_repository.dart`
- `lib/features/trackers/domain/tracker_repository.dart`
- `lib/features/today/domain/today_overview.dart`
- `lib/app/app_router.dart`
