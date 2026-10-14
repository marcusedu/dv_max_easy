import 'package:dv_max_easy/features/convert/domain/convert_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a media url stays a download and a local file can be converted', () {
    expect(
      localMediaPath('https://cdn.example/video.mp4', home: '/Users/me'),
      isNull,
    );
    expect(
      localMediaPath('/tmp/filme.avi', home: '/Users/me'),
      '/tmp/filme.avi',
    );
    expect(
      localMediaPath('~/Movies/clipe.mkv', home: '/Users/me'),
      '/Users/me/Movies/clipe.mkv',
    );
    expect(
      localMediaPath(r'C:\Videos\audio.mp3', home: ''),
      r'C:\Videos\audio.mp3',
    );
    expect(localMediaPath('/tmp/notas.txt', home: '/Users/me'), isNull);
    expect(
      looksLikePastedLocal('', '/tmp/filme.mp4', home: '/Users/me'),
      isTrue,
    );
    expect(
      looksLikePastedLocal(
        '/tmp/filme.mp',
        '/tmp/filme.mp4',
        home: '/Users/me',
      ),
      isFalse,
    );
  });

  test('conversion reencodes beside the original and never replaces it', () {
    expect(
      suggestConvertPath('/tmp/filme.avi', ConvertTarget.mp4, (_) => false),
      '/tmp/filme.mp4',
    );
    expect(
      suggestConvertPath('/tmp/filme.mp4', ConvertTarget.mp4, (_) => false),
      '/tmp/filme-convert.mp4',
    );
    expect(
      suggestConvertPath(
        r'C:\Videos\filme.mov',
        ConvertTarget.mp3,
        (_) => false,
      ),
      r'C:\Videos\filme.mp3',
    );

    final video = convertArguments(
      input: '/tmp/a.avi',
      output: '/tmp/a.mp4',
      target: ConvertTarget.mp4,
      audio: true,
    ).join(' ');
    expect(video, contains('libx264'));
    expect(video, contains('aac'));
    expect(video, contains('+faststart'));

    final audio = convertArguments(
      input: '/tmp/a.mp4',
      output: '/tmp/a.mp3',
      target: ConvertTarget.mp3,
      audio: true,
    ).join(' ');
    expect(audio, contains('-vn'));
    expect(audio, contains('libmp3lame'));
    expect(audio, isNot(contains('libx264')));
  });

  test('probe json tells video apart from audio', () {
    final facts = convertFactsFromProbe('''
{"format":{"duration":"12"},"streams":[{"codec_type":"audio"}]}
''');
    expect(facts?.video, isFalse);
    expect(facts?.audio, isTrue);
    expect(facts?.duration, const Duration(seconds: 12));
    expect(convertFactsFromProbe('nope'), isNull);
  });

  test('join arguments generate concat commands and list content', () {
    final list = generateConcatListContent([
      '/tmp/part1.mp4',
      "/tmp/part 2's.mp4",
    ]);
    expect(list, contains("file '/tmp/part1.mp4'"));
    expect(list, contains(r"file '/tmp/part 2'\''s.mp4'"));

    final copy = joinArguments(
      listFilePath: '/tmp/list.txt',
      output: '/tmp/unido.mp4',
      target: ConvertTarget.mp4,
      reencode: false,
    ).join(' ');
    expect(copy, contains('-c copy'));
    expect(copy, contains('-f concat'));
    expect(copy, contains('/tmp/unido.mp4'));

    final reencode = joinArguments(
      listFilePath: '/tmp/list.txt',
      output: '/tmp/unido.mp4',
      target: ConvertTarget.mp4,
      reencode: true,
    ).join(' ');
    expect(reencode, contains('libx264'));
    expect(reencode, contains('aac'));

    final audioJoin = joinArguments(
      listFilePath: '/tmp/list.txt',
      output: '/tmp/unido.mp3',
      target: ConvertTarget.mp3,
      reencode: true,
    ).join(' ');
    expect(audioJoin, contains('-vn'));
    expect(audioJoin, contains('libmp3lame'));

    expect(
      suggestJoinPath(
        ['/tmp/a.mp4', '/tmp/b.mp4'],
        ConvertTarget.mp4,
        (_) => false,
      ),
      '/tmp/unido.mp4',
    );
  });
}
