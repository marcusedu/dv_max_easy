abstract interface class Log {
  void info(String message);

  void error(String message, {Object? cause});
}

final class MemoryLog implements Log {
  final lines = <String>[];

  @override
  void info(String message) {
    lines.add(message);
  }

  @override
  void error(String message, {Object? cause}) {
    lines.add(cause == null ? message : '$message ($cause)');
  }
}
