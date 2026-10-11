import 'package:dv_max_easy/features/downloads/domain/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryQueryProvider =
    NotifierProvider<LibraryQueryController, LibraryQuery>(
      LibraryQueryController.new,
    );

final class LibraryQueryController extends Notifier<LibraryQuery> {
  @override
  LibraryQuery build() => const LibraryQuery();

  void setText(String text) => state = state.copyWith(text: text);

  void setHost(String? host) =>
      state = state.copyWith(clearHost: host == null, host: host);

  void setProfile(String? profile) =>
      state = state.copyWith(clearProfile: profile == null, profile: profile);

  void setType(String? type) =>
      state = state.copyWith(clearType: type == null, type: type);

  void setDisk(DiskFilter disk) => state = state.copyWith(disk: disk);

  void focusUrl(String url) => state = LibraryQuery(text: url);
}
