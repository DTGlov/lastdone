# Dun’s Planner

Dun’s Planner is the calendar mode of the existing Timeline destination. History
answers what was completed; Planner answers what is due or expected next. It is
read-only: projected due dates and subscription charges are presentation data,
never synthetic database events.

## Data and projections

`PlannerViewModel` combines active `TrackerOverview` values, active subscriptions,
and a bounded joined completion query from `TimelineRepository`. The query loads
completion rows for the current month and the following eleven months. Tracker
metadata is joined in one query, so calendar cells and agenda rows never perform
database work or N+1 lookups.

Scheduled trackers project their first due date until a genuine completion exists;
after that, the existing `TodayClassifier.nextDueDateFor` cadence calculation is
used. Active subscriptions project their stored next charge with the existing
calendar-aware billing rules. Archived trackers and cancelled subscriptions are
excluded from projections, while archived completion history remains visible.

Monthly and yearly recurrence uses calendar arithmetic, including clamping the
29th–31st to the final day of shorter months and handling leap years. Nothing is
written when a projection is generated, and stored subscription charge dates are
never mutated. Completion rows remain factual and are reconciled with a matching
due projection so a tracker completed on its due date is not shown twice.

## Window, cache, and refresh

The view model keeps a date-indexed immutable map keyed by `PlannerDate`, making
marker and selected-day lookup constant-time. It refreshes from the existing
overview and subscription streams after edits, completions, Undo, archive or
restore operations, and when the app resumes on a new local calendar day. Late
requests are ignored through a generation guard; the visible map is replaced
atomically.

`History | Planner` is session-local state inside the persistent Timeline branch.
History search, filters, pagination, and its stable scroll/layout architecture
remain owned by `TimelineViewModel`.

## Presentation and accessibility

The Planner uses the shared themed `TableCalendar` styling with a twelve-month
bounded horizontal calendar. Due, charge, handled, and overdue markers use both
shape and semantics rather than colour alone. The selected-day agenda orders due
trackers, subscription charges, and completions, and routes each row to its
existing details screen. Dun’s idle artwork keeps quiet days calm; subscription
days use the subscription artwork and fully handled days can use the celebration
state in future presentation refinements.

The calendar and agenda use semantic labels, compact surfaces, safe scrolling,
dark-mode tokens, and no decorative motion that is required for comprehension.
Reduced motion therefore presents the same data without transition effects.

## Limitations and manual testing

The planner does not sync with Apple or Google Calendar, reschedule items, mark
items done inline, show subscription payment history, convert currencies, or add
notification types. Test month navigation across all twelve months, future first
due dates, month-end and leap-year rules, completions and Undo, archive/cancel
refreshes, separated currency totals, detail navigation, empty/error states,
large text, compact widths, dark mode, semantics, and reduced motion manually.

## Database opening recovery

Planner adds no tables, columns, indexes, or schema-version changes. During
manual testing an existing development database failed with
`duplicate column name: archived_at`. EverDun uses creation strategy A:
`onCreate` creates the complete current schema, while `onUpgrade` applies each
historical version greater than the recorded version and no greater than the
requested version. The inconsistent development database had already received
the archive column while its recorded version still caused that migration to
run, exposing that additive migrations were not idempotent.

The migration runner now checks `PRAGMA table_info` before every additive
column alteration, validates that the expected table exists, and skips only an
already-present column. It does not catch generic SQL errors. Table and index
creation is also explicitly idempotent for a partially completed development
upgrade. Fresh creation and upgrades converge on the same version 7 schema
without deleting trackers, completions, subscriptions, reminders, or profile
preferences. Deleting the database was rejected because preserving user data
is the safer recovery path.
