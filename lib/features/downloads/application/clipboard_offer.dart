import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clipboardOfferProvider =
    NotifierProvider<ClipboardOfferController, String?>(
      ClipboardOfferController.new,
    );

final class ClipboardOfferController extends Notifier<String?> {
  final Set<String> _seen = {};

  @override
  String? build() => null;

  void offer(String? raw, {required bool enabled}) {
    if (!enabled) {
      return;
    }
    final url = raw?.trim() ?? '';
    if (!isHttpUrl(url) || _seen.contains(url) || state == url) {
      return;
    }
    state = url;
  }

  void dismiss() {
    final current = state;
    if (current != null) {
      _seen.add(current);
    }
    state = null;
  }
}
