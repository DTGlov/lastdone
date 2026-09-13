import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/app_clock.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

enum SubscriptionsLoadState { loading, content, empty, error }

class SubscriptionsViewModel extends ChangeNotifier {
  SubscriptionsViewModel({required this.repository, required this.clock}) {
    currentDate = _dateOnly(clock.now);
    _subscription = repository.watchSubscriptions().listen(
      _receive,
      onError: _receiveError,
    );
  }
  final SubscriptionRepository repository;
  final AppClock clock;
  late DateTime currentDate;
  SubscriptionsLoadState state = SubscriptionsLoadState.loading;
  List<Subscription> subscriptions = const [];
  String? errorMessage;
  StreamSubscription<List<Subscription>>? _subscription;
  bool _disposed = false;

  List<Subscription> get activeSubscriptions =>
      subscriptions.where((value) => value.active).toList(growable: false);
  List<Subscription> get inactiveSubscriptions =>
      subscriptions.where((value) => !value.active).toList(growable: false);
  List<Subscription> get upcoming {
    final values = activeSubscriptions.toList();
    values.sort((a, b) => nextCharge(a).compareTo(nextCharge(b)));
    return values;
  }

  Map<String, int> get monthlyTotals {
    final totals = <String, int>{};
    for (final subscription in activeSubscriptions) {
      totals.update(
        subscription.currency,
        (value) => value + monthlyEstimateMinor(subscription),
        ifAbsent: () => monthlyEstimateMinor(subscription),
      );
    }
    return Map.unmodifiable(totals);
  }

  DateTime nextCharge(Subscription subscription) => nextChargeOnOrAfter(
    subscription.nextChargeDate,
    subscription.frequency,
    currentDate,
  );

  Future<void> retry() async {
    if (_disposed) return;
    state = SubscriptionsLoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.refreshSubscriptions();
    } catch (_) {
      _receiveError();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _receive(List<Subscription> value) {
    if (_disposed) return;
    currentDate = _dateOnly(clock.now);
    subscriptions = List.unmodifiable(value);
    state = value.isEmpty
        ? SubscriptionsLoadState.empty
        : SubscriptionsLoadState.content;
    errorMessage = null;
    notifyListeners();
  }

  void _receiveError([Object? error, StackTrace? stackTrace]) {
    if (_disposed) return;
    state = SubscriptionsLoadState.error;
    errorMessage = 'We could not load your subscriptions. Please try again.';
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
