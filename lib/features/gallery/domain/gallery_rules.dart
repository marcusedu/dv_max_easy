const shortVideoMs = 60000;
const resumeMarginMs = 3000;

enum GalleryEnd { stay, repeat, next }

enum PlaybackFinish { loop, stop, repeat, advance }

enum GalleryStep { previous, next, none }

GalleryEnd parseGalleryEnd(String raw) {
  return switch (raw) {
    'repeat' => GalleryEnd.repeat,
    'next' => GalleryEnd.next,
    _ => GalleryEnd.stay,
  };
}

const galleryVideoExtensions = {'mp4', 'mkv', 'webm', 'mov', 'm4v', 'avi'};

PlaybackFinish finishFor({required int? durationMs, required GalleryEnd end}) {
  final known = durationMs != null && durationMs > 0;
  if (known && durationMs <= shortVideoMs) {
    return PlaybackFinish.loop;
  }
  return switch (end) {
    GalleryEnd.stay => PlaybackFinish.stop,
    GalleryEnd.repeat => PlaybackFinish.repeat,
    GalleryEnd.next => PlaybackFinish.advance,
  };
}

GalleryStep scrollStep({required double dy, required bool inverted}) {
  if (dy == 0) {
    return GalleryStep.none;
  }
  final down = dy > 0;
  final forward = inverted ? !down : down;
  return forward ? GalleryStep.next : GalleryStep.previous;
}

/// Positive means the next video.
///
/// A mouse wheel is a [PointerScrollEvent] (positive dy = next). A Mac
/// trackpad and a Magic Mouse are pan/zoom, and that pan is the opposite
/// sign of the scroll signal. Negate pan so both inputs share one sign.
double galleryFeedDelta({
  required double scrollDy,
  required double scrollDx,
  required double panDy,
  required double panDx,
}) {
  if (scrollDy != 0) {
    return scrollDy;
  }
  if (scrollDx != 0) {
    return scrollDx;
  }
  if (panDy != 0) {
    return -panDy;
  }
  return -panDx;
}

/// A failed reopen reports position 0. That must not erase a stored resume.
bool blocksResumeOverwrite({
  required int incomingMs,
  required int storedMs,
  required bool reached,
}) {
  return !reached && storedMs >= resumeMarginMs && incomingMs < resumeMarginMs;
}

int rememberedPositionMs({required int positionMs, required int? durationMs}) {
  if (positionMs < resumeMarginMs) {
    return 0;
  }
  if (durationMs != null &&
      durationMs > 0 &&
      positionMs >= durationMs - resumeMarginMs) {
    return 0;
  }
  return positionMs;
}
