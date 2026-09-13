abstract interface class AppClock {
  DateTime get now;
}

class SystemAppClock implements AppClock {
  @override
  DateTime get now => DateTime.now();
}

class FixedAppClock implements AppClock {
  const FixedAppClock(this.now);
  @override
  final DateTime now;
}
