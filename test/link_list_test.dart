import 'package:dv_max_easy/features/lists/domain/link_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new list accepts a link once', () {
    final created = createLinkList(const [], id: '1');
    expect(created?.name, 'Lista');
    final added = addLink(created!, 'https://example.com/a');
    expect(added.errorCode, isNull);
    expect(added.list.urls, ['https://example.com/a']);
    expect(addLink(added.list, 'https://example.com/a').errorCode, 'duplicate');
    expect(addLink(added.list, 'não é link').errorCode, 'bad_url');
    expect(removeLink(added.list, 'https://example.com/a').urls, isEmpty);
  });

  test('names stay unique and the list has a ceiling', () {
    final first = createLinkList(const [], id: '1')!;
    final second = createLinkList([first], id: '2')!;
    expect(second.name, 'Lista 2');
    expect(renameError('   '), 'empty_name');
    expect(renameError('Filmes salvos'), isNull);

    final full = LinkList(
      id: '1',
      name: 'Lista',
      urls: [
        for (var index = 0; index < maxLinksInList; index++) 'https://e/$index',
      ],
    );
    expect(addLink(full, 'https://e/extra').errorCode, 'full');
    final many = [
      for (var index = 0; index < maxLinkLists; index++)
        LinkList(id: '$index', name: 'Lista $index', urls: const []),
    ];
    expect(createLinkList(many, id: 'novo'), isNull);
  });
}
