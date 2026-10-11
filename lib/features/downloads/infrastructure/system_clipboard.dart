import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class ClipboardReader {
  Future<String?> readText();
}

final clipboardReaderProvider = Provider<ClipboardReader>(
  (ref) => const SystemClipboardReader(),
);

final class SystemClipboardReader implements ClipboardReader {
  const SystemClipboardReader();

  @override
  Future<String?> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
