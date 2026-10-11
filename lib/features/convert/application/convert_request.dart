import 'package:flutter_riverpod/flutter_riverpod.dart';

final convertRequestProvider = NotifierProvider<ConvertRequest, String?>(
  ConvertRequest.new,
);

final class ConvertRequest extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String path) => state = path;
}
