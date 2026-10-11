String? notableErrorLine(String line) {
  final text = line.trim();
  if (text.isEmpty) {
    return null;
  }
  final lower = text.toLowerCase();
  final named =
      text.startsWith('ERROR:') ||
      lower.contains('file name too long') ||
      lower.contains('filename too long') ||
      lower.contains('name too long') ||
      lower.contains('errno 63') ||
      lower.contains('errno 36') ||
      lower.contains('enametoolong');
  if (!named) {
    return null;
  }
  if (text.length <= 280) {
    return text;
  }
  return text.substring(0, 280);
}

String classifyDownloadFailure(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('file name too long') ||
      text.contains('filename too long') ||
      text.contains('name too long') ||
      text.contains('errno 63') ||
      text.contains('errno 36') ||
      text.contains('enametoolong')) {
    return 'filename_too_long';
  }
  if (text.contains('private video') || text.contains('video is private')) {
    return 'private_video';
  }
  if (text.contains('unavailable') || text.contains('has been removed')) {
    return 'unavailable';
  }
  if (text.contains('sign in') ||
      text.contains('confirm you') ||
      text.contains('not a bot')) {
    return 'login_required';
  }
  if (text.contains('unsupported url')) {
    return 'unsupported_url';
  }
  if (text.contains('http error 403') || text.contains('forbidden')) {
    return 'forbidden';
  }
  if (text.contains('unable to extract') || text.contains('no video formats')) {
    return 'extract_failed';
  }
  if (text.contains('ffprobe') || text.contains('ffmpeg')) {
    return 'ffmpeg_failed';
  }
  if (text.contains('network') ||
      text.contains('timed out') ||
      text.contains('temporary failure') ||
      text.contains('connection refused') ||
      text.contains('connection reset')) {
    return 'network';
  }
  return 'failed';
}

String? shortFailureDetail(String? raw) {
  if (raw == null) {
    return null;
  }
  var text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  const prefix = 'ERROR:';
  if (text.startsWith(prefix)) {
    text = text.substring(prefix.length).trim();
  }
  if (text.isEmpty) {
    return null;
  }
  return text;
}
