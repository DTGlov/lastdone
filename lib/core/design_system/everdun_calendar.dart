import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'app_icons.dart';
import 'design_tokens.dart';

/// The inline calendar surface used by Planner and the modal date picker.
class EverDunMonthCalendar<T> extends StatelessWidget {
  const EverDunMonthCalendar({
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    this.selectedDayPredicate,
    this.eventLoader,
    this.calendarBuilders,
    this.headerStyle,
    this.daysOfWeekStyle,
    this.calendarStyle,
    super.key,
  });
  final DateTime firstDay, lastDay, focusedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final bool Function(DateTime day)? selectedDayPredicate;
  final List<T> Function(DateTime day)? eventLoader;
  final CalendarBuilders<T>? calendarBuilders;
  final HeaderStyle? headerStyle;
  final DaysOfWeekStyle? daysOfWeekStyle;
  final CalendarStyle? calendarStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TableCalendar<T>(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: focusedDay,
      selectedDayPredicate: selectedDayPredicate,
      eventLoader: eventLoader,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      calendarBuilders: calendarBuilders ?? CalendarBuilders<T>(),
      headerStyle:
          headerStyle ??
          HeaderStyle(
            titleTextStyle: theme.textTheme.titleMedium!,
            formatButtonVisible: false,
            leftChevronIcon: const Icon(AppIcons.previous),
            rightChevronIcon: const Icon(AppIcons.next),
          ),
      daysOfWeekStyle:
          daysOfWeekStyle ??
          DaysOfWeekStyle(
            weekdayStyle: theme.textTheme.labelSmall!,
            weekendStyle: theme.textTheme.labelSmall!,
          ),
      calendarStyle:
          calendarStyle ??
          CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: theme.textTheme.bodyMedium!,
            weekendTextStyle: theme.textTheme.bodyMedium!,
            disabledTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface.withValues(alpha: .35),
            ),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary),
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
            selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
    );
  }
}

Future<DateTime?> showEverDunCalendar({
  required BuildContext context,
  required DateTime firstDay,
  required DateTime lastDay,
  required DateTime initialDay,
  required String title,
  String? supportingText,
  bool Function(DateTime day)? enabledDayPredicate,
}) => showModalBottomSheet<DateTime>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _EverDunCalendarSheet(
    firstDay: firstDay,
    lastDay: lastDay,
    initialDay: initialDay,
    title: title,
    supportingText: supportingText,
    enabledDayPredicate: enabledDayPredicate,
  ),
);

class _EverDunCalendarSheet extends StatefulWidget {
  const _EverDunCalendarSheet({
    required this.firstDay,
    required this.lastDay,
    required this.initialDay,
    required this.title,
    this.supportingText,
    this.enabledDayPredicate,
  });
  final DateTime firstDay, lastDay, initialDay;
  final String title;
  final String? supportingText;
  final bool Function(DateTime day)? enabledDayPredicate;

  @override
  State<_EverDunCalendarSheet> createState() => _EverDunCalendarSheetState();
}

class _EverDunCalendarSheetState extends State<_EverDunCalendarSheet> {
  late DateTime _focusedDay = _dateOnly(widget.initialDay);
  late DateTime? _selectedDay = _dateOnly(widget.initialDay);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          if (widget.supportingText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(widget.supportingText!),
          ],
          const SizedBox(height: AppSpacing.sm),
          TableCalendar<void>(
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay, day),
            enabledDayPredicate: widget.enabledDayPredicate,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
            headerStyle: HeaderStyle(
              titleTextStyle: theme.textTheme.titleMedium!,
              formatButtonVisible: false,
              leftChevronIcon: const Icon(AppIcons.previous),
              rightChevronIcon: const Icon(AppIcons.next),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.labelSmall!,
              weekendStyle: theme.textTheme.labelSmall!,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: theme.textTheme.bodyMedium!,
              weekendTextStyle: theme.textTheme.bodyMedium!,
              disabledTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary),
              ),
              todayTextStyle: theme.textTheme.bodyMedium!,
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
              ),
              selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _selectedDay == null
                ? null
                : () => Navigator.pop(context, _selectedDay),
            child: const Text('Use this date'),
          ),
        ],
      ),
    );
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
