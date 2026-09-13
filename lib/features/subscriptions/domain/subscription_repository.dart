import 'subscription.dart';

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watchSubscriptions();
  Future<void> refreshSubscriptions();
  Future<void> createSubscription(Subscription subscription);
  Future<void> updateSubscription(Subscription subscription);
  Future<Subscription?> getSubscription(String id);
}

class UnavailableSubscriptionRepository implements SubscriptionRepository {
  const UnavailableSubscriptionRepository();

  @override
  Stream<List<Subscription>> watchSubscriptions() => Stream.value(const []);

  @override
  Future<void> refreshSubscriptions() async {}

  @override
  Future<void> createSubscription(Subscription subscription) =>
      Future.error(StateError('Subscription storage is unavailable'));

  @override
  Future<void> updateSubscription(Subscription subscription) =>
      Future.error(StateError('Subscription storage is unavailable'));

  @override
  Future<Subscription?> getSubscription(String id) async => null;
}
