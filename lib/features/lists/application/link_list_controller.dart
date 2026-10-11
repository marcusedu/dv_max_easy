import 'package:dv_max_easy/features/lists/domain/link_list.dart';
import 'package:dv_max_easy/features/lists/infrastructure/json_link_list_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final linkListControllerProvider =
    AsyncNotifierProvider<LinkListController, LinkListsView>(
      LinkListController.new,
    );

final class LinkListsView {
  const LinkListsView(this.lists, {this.selectedId, this.errorCode});

  final List<LinkList> lists;
  final String? selectedId;
  final String? errorCode;

  LinkList? get selected {
    for (final list in lists) {
      if (list.id == selectedId) {
        return list;
      }
    }
    return lists.isEmpty ? null : lists.first;
  }

  LinkListsView copyWith({
    List<LinkList>? lists,
    String? selectedId,
    String? errorCode,
    bool clearError = false,
  }) {
    return LinkListsView(
      lists ?? this.lists,
      selectedId: selectedId ?? this.selectedId,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

final class LinkListController extends AsyncNotifier<LinkListsView> {
  @override
  Future<LinkListsView> build() async {
    final lists = await ref.read(linkListStoreProvider).load();
    return LinkListsView(lists);
  }

  LinkListsView get _current => state.asData?.value ?? const LinkListsView([]);

  void select(String id) {
    state = AsyncData(_current.copyWith(selectedId: id, clearError: true));
  }

  Future<void> create() async {
    final created = createLinkList(
      _current.lists,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    if (created == null) {
      state = AsyncData(_current.copyWith(errorCode: 'too_many'));
      return;
    }
    final lists = [..._current.lists, created];
    await ref.read(linkListStoreProvider).save(lists);
    state = AsyncData(LinkListsView(lists, selectedId: created.id));
  }

  Future<void> rename(String id, String name) async {
    final error = renameError(name);
    if (error != null) {
      state = AsyncData(_current.copyWith(errorCode: error));
      return;
    }
    final lists = [
      for (final list in _current.lists)
        if (list.id == id) list.copyWith(name: name.trim()) else list,
    ];
    await ref.read(linkListStoreProvider).save(lists);
    state = AsyncData(_current.copyWith(lists: lists, clearError: true));
  }

  Future<void> delete(String id) async {
    final lists = [
      for (final list in _current.lists)
        if (list.id != id) list,
    ];
    await ref.read(linkListStoreProvider).save(lists);
    final selected = lists.isEmpty ? null : lists.first.id;
    state = AsyncData(LinkListsView(lists, selectedId: selected));
  }

  Future<bool> addUrl(String id, String raw) async {
    final index = _current.lists.indexWhere((list) => list.id == id);
    if (index < 0) {
      return false;
    }
    final change = addLink(_current.lists[index], raw);
    if (change.errorCode != null) {
      state = AsyncData(_current.copyWith(errorCode: change.errorCode));
      return false;
    }
    final lists = [..._current.lists];
    lists[index] = change.list;
    await ref.read(linkListStoreProvider).save(lists);
    state = AsyncData(
      _current.copyWith(lists: lists, selectedId: id, clearError: true),
    );
    return true;
  }

  Future<void> removeUrl(String id, String url) async {
    final lists = [
      for (final list in _current.lists)
        if (list.id == id) removeLink(list, url) else list,
    ];
    await ref.read(linkListStoreProvider).save(lists);
    state = AsyncData(_current.copyWith(lists: lists, clearError: true));
  }
}
