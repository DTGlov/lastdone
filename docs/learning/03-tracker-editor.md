# Phase 3: Tracker creation and editing

Phase 3 replaces the Create placeholder with one reusable tracker editor. The
same bottom sheet is used for creating a tracker and editing its metadata. A
tracker can be scheduled with a calendar-based repeat rule or left unscheduled
for things that happen whenever they are ready.

## The create and edit journeys

The Create FAB is available from Today, Timeline, and You. It opens the editor
with a name, category, icon, colour, last-completed choice, and repeat schedule.
The form validates locally and keeps its values when persistence fails. On a
successful create, the sheet closes and Today receives the refreshed overview.

Tapping a Today card opens the same editor in edit mode. Edit mode shows the
latest completion as context, but deliberately does not edit or rewrite
completion history. Phase 4 can introduce explicit tracker details and
completion actions.

## State and storage

`TrackerEditorViewModel` owns form state, validation, dirty-state detection,
loading, and recoverable errors. `TrackerEditorSheet` only renders that state
and forwards user intent.

`LocalTrackerRepository.createTracker` writes the tracker and its optional
initial completion in one SQLite transaction. This means a chosen initial date
cannot leave an orphan completion or a tracker without its required data. User
tracker IDs are generated from the injected clock, while the repository
transaction is the persistence boundary that prevents partial writes.

Categories, icons, and colours are stored as stable keys or enum names rather
than display labels or `IconData` code points. This keeps saved onboarding rows
compatible with the editor. `updateTracker` changes only the tracker row, so
editing cadence or metadata does not silently rewrite history. The repository
publishes a refreshed overview after each successful mutation, allowing Today
to update without polling.

## Navigation and layout

The shell in `lib/app/app_router.dart` gives Today, Timeline, and You equal
navigation destinations. The Create FAB uses the Scaffold's end-floating
position and SafeArea support, leaving navigation labels and the iPhone home
indicator unobscured. Today cards are padded below the FAB and open the editor
instead of using a dead tap.

The editor is a scrollable, keyboard-safe modal sheet. Controls have semantic
selected states and at least 44-point targets. Built-in animated containers
respect `MediaQuery.disableAnimations`; no animation dependency was added.

## Manual test flow

1. Open Create from each of the three shell tabs and confirm the FAB does not
   cover navigation or content.
2. Create scheduled and unscheduled trackers, including Today and a past last
   completion date. Try a future date, blank name, long name, and invalid
   interval.
3. Confirm a newly created tracker appears on Today immediately and is grouped
   according to its due date.
4. Tap a Today card, edit each metadata field, and confirm completion history
   remains unchanged. Dismiss a dirty form and verify the confirmation.
5. Relaunch the app, then check light/dark mode, keyboard behaviour, compact
   widths, large text, and scrolling.

## Intentionally deferred

Done-today actions, undo, full completion history, archive/delete/restore,
reminder scheduling, notification permission, Life Rhythm scoring, cloud sync,
and backend services remain out of scope. The empty Today action now opens the
same editor, but the broader tracker-details experience remains Phase 4 work.

```mermaid
flowchart LR
  A[Create FAB or Today card] --> B[TrackerEditorViewModel]
  B --> C{Valid form?}
  C -- No --> B
  C -- Yes --> D[SQLite transaction]
  D --> E[Tracker + optional Completion]
  E --> F[Repository overview refresh]
  F --> G[TodayViewModel classification]
  G --> H[Today cards]
```

Important references:

- `lib/features/trackers/presentation/tracker_editor_view_model.dart`
- `lib/features/trackers/presentation/tracker_editor_sheet.dart`
- `lib/features/trackers/data/local_tracker_repository.dart`
- `lib/features/trackers/domain/tracker.dart`
- `lib/app/app_router.dart`
