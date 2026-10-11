import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a middle cut stays out and the ends join', () {
    const duration = Duration(seconds: 60);
    final kept = keptAfterCuts(duration, const [
      Span(Duration.zero, Duration(seconds: 5)),
      Span(Duration(seconds: 20), Duration(seconds: 40)),
    ]);

    expect(kept, [
      const Span(Duration(seconds: 5), Duration(seconds: 20)),
      const Span(Duration(seconds: 40), Duration(seconds: 60)),
    ]);
    expect(describeKept(kept), '00:05–00:20 + 00:40–01:00');
    expect(cutsChangeTheFile(duration, kept), isTrue);
  });

  test('clock text accepts seconds and colon times', () {
    expect(parseClock('5'), const Duration(seconds: 5));
    expect(parseClock('5,5'), const Duration(milliseconds: 5500));
    expect(parseClock('0:20'), const Duration(seconds: 20));
    expect(
      parseClock('1:02:03'),
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
    expect(parseClock('1:60'), isNull);
    expect(parseClock(''), isNull);
  });

  test('keeping one span removes everything else', () {
    final removed = keepOnly(
      const Duration(seconds: 60),
      const Span(Duration(seconds: 5), Duration(seconds: 20)),
    );
    expect(keptAfterCuts(const Duration(seconds: 60), removed), [
      const Span(Duration(seconds: 5), Duration(seconds: 20)),
    ]);
  });

  test('the saved cut sits beside the original', () {
    expect(
      suggestCutPath('/tmp/filme.mkv', (_) => false),
      '/tmp/filme-corte.mkv',
    );
    expect(
      suggestCutPath('/tmp/filme.webm', (_) => false),
      '/tmp/filme-corte.mp4',
    );
    expect(
      suggestCutPath(
        '/tmp/filme.mp4',
        (path) => path.endsWith('filme-corte.mp4'),
      ),
      '/tmp/filme-corte-2.mp4',
    );
    expect(
      suggestCutPath(r'C:\Videos\filme.mov', (_) => false),
      r'C:\Videos\filme-corte.mov',
    );
  });

  test('probe json reports duration and audio', () {
    final facts = mediaFactsFromProbe('''
{"format":{"duration":"60.5"},"streams":[{"codec_type":"video"},{"codec_type":"audio"}]}
''');
    expect(facts?.duration, const Duration(milliseconds: 60500));
    expect(facts?.audio, isTrue);
    expect(mediaFactsFromProbe('not json'), isNull);
    expect(probeArguments('/tmp/a.mp4').first, '-v');
  });

  test('the cut reencodes the kept spans and skips a whole file', () {
    final args = cutArguments(
      input: '/tmp/a.mp4',
      output: '/tmp/a-corte.mp4',
      kept: const [
        Span(Duration(seconds: 5), Duration(seconds: 20)),
        Span(Duration(seconds: 40), Duration(seconds: 60)),
      ],
      audio: true,
    );
    expect(args, isNotNull);
    final filter = args!.join(' ');
    expect(filter, contains('trim=start=5.000:end=20.000'));
    expect(filter, contains('trim=start=40.000:end=60.000'));
    expect(filter, contains('concat=n=2:v=1:a=1'));
    expect(filter, contains('libx264'));
    expect(
      cutArguments(
        input: '/tmp/a.mp4',
        output: '/tmp/a-corte.mp4',
        kept: const [Span(Duration.zero, Duration(seconds: 60))],
        audio: false,
      ),
      isNotNull,
    );
    expect(
      cutArguments(
        input: '/tmp/a.mp4',
        output: '/tmp/a-corte.mp4',
        kept: const [],
        audio: false,
      ),
      isNull,
    );
    expect(
      cutsChangeTheFile(const Duration(seconds: 60), const [
        Span(Duration.zero, Duration(seconds: 60)),
      ]),
      isFalse,
    );
  });

  test('ffmpeg out_time_ms is treated as microseconds', () {
    expect(
      progressFraction('out_time_ms=2500000', const Duration(seconds: 10)),
      closeTo(0.25, 0.0001),
    );
    expect(
      progressFraction('out_time_us=2500000', const Duration(seconds: 10)),
      closeTo(0.25, 0.0001),
    );
    expect(progressFraction('frame=1', const Duration(seconds: 10)), isNull);
  });

  test('video files are the ones the editor can open', () {
    expect(isVideoFile('/tmp/a.MKV'), isTrue);
    expect(isVideoFile('/tmp/a.mp3'), isFalse);
  });
}
