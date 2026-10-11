abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

final class FixedClock implements Clock {
  FixedClock(this.instant);

  DateTime instant;

  @override
  DateTime now() => instant;
}
