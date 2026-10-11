import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paste of a whole URL starts, typing one letter does not', () {
    expect(
      looksLikePastedUrl('', 'https://www.youtube.com/watch?v=abcdefghijk'),
      isTrue,
    );
    expect(
      looksLikePastedUrl('https://www.youtube.com/watch?v=abcdefghij', 'https://www.youtube.com/watch?v=abcdefghijk'),
      isFalse,
    );
  });

  test('films profile asks for 1080p, japanese audio and embedded subs', () {
    final args = downloadArguments(
      profile: filmsPreset(),
      destination: '/Users/me/Movies',
      ffmpegPath: '/opt/homebrew/bin/ffmpeg',
      url: 'https://www.youtube.com/watch?v=abcdefghijk',
    );

    expect(args, contains('--no-playlist'));
    expect(
      args[args.indexOf('-f') + 1],
      'bv*[height<=1080]+ba[language^=ja]/bv*[height<=1080]+ba[language^=pt]/bv*[height<=1080]+ba/b[height<=1080]',
    );
    expect(args, contains('--embed-subs'));
    expect(args, contains('pt.*,-live_chat'));
    expect(args, isNot(contains('-N')));
  });

  test('music profile extracts mp3 and does not embed subtitles', () {
    final args = downloadArguments(
      profile: musicPreset().copyWith(rateLimit: '2M', concurrentFragments: 4),
      destination: '/Users/me/Music',
      ffmpegPath: '/opt/homebrew/bin/ffmpeg',
      url: 'https://www.youtube.com/watch?v=abcdefghijk',
    );

    expect(args, contains('-x'));
    expect(args, contains('mp3'));
    expect(args, isNot(contains('--embed-subs')));
    expect(args, containsAll(['-r', '2M', '-N', '4']));
  });

  test('progress JSON and dest line update the job', () {
    final progress = parseDownloadLine(
      'download:{"event":"download","status":"downloading","downloaded":"50","total":"100","speed":"2000000","eta":"3"}',
    );
    expect(progress?.fraction, 0.5);

    final dest = parseDownloadLine('dest:/Users/me/Movies/Filme [abc].mkv');
    expect(dest?.outputPath, '/Users/me/Movies/Filme [abc].mkv');
  });
}
