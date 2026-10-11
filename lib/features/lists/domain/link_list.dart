import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';

const maxLinkLists = 30;
const maxLinksInList = 100;

final class LinkList {
  const LinkList({required this.id, required this.name, required this.urls});

  final String id;
  final String name;
  final List<String> urls;

  LinkList copyWith({String? name, List<String>? urls}) {
    return LinkList(id: id, name: name ?? this.name, urls: urls ?? this.urls);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'urls': urls};
  }

  static LinkList? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final raw = json['urls'];
    if (id is! String || id.isEmpty || name is! String || raw is! List) {
      return null;
    }
    final urls = [
      for (final item in raw)
        if (item is String && isHttpUrl(item)) item,
    ];
    return LinkList(id: id, name: name.trim(), urls: urls);
  }
}

final class LinkChange {
  const LinkChange(this.list, {this.errorCode});

  final LinkList list;
  final String? errorCode;
}

LinkList? createLinkList(List<LinkList> lists, {required String id}) {
  if (lists.length >= maxLinkLists || id.isEmpty) {
    return null;
  }
  final taken = {for (final list in lists) list.name};
  var name = 'Lista';
  var number = 2;
  while (taken.contains(name)) {
    name = 'Lista $number';
    number += 1;
  }
  return LinkList(id: id, name: name, urls: const []);
}

String? renameError(String name) {
  final text = name.trim();
  if (text.isEmpty || text.length > 80) {
    return 'empty_name';
  }
  return null;
}

LinkChange addLink(LinkList list, String raw) {
  final url = raw.trim();
  if (!isHttpUrl(url)) {
    return LinkChange(list, errorCode: 'bad_url');
  }
  if (list.urls.contains(url)) {
    return LinkChange(list, errorCode: 'duplicate');
  }
  if (list.urls.length >= maxLinksInList) {
    return LinkChange(list, errorCode: 'full');
  }
  return LinkChange(list.copyWith(urls: [...list.urls, url]));
}

LinkList removeLink(LinkList list, String url) {
  return list.copyWith(
    urls: [
      for (final item in list.urls)
        if (item != url) item,
    ],
  );
}
