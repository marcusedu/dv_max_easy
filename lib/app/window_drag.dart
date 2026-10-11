import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const windowChannel = MethodChannel('dvmax.files');

Future<void> beginWindowDrag() async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await windowChannel.invokeMethod<void>('drag');
  } on MissingPluginException {
    return;
  }
}
