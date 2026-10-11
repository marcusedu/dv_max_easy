final class DownloadJob {
  const DownloadJob({
    required this.id,
    required this.url,
    required this.profileName,
    required this.running,
    this.fraction,
    this.detail,
    this.outputPath,
    this.error,
    this.errorDetail,
    this.audio = false,
    this.qualityLabel,
    this.containerLabel = '',
    this.destination,
    this.downloaded,
    this.total,
    this.speed,
    this.eta,
    this.thumbnailUrl,
  });

  final String id;
  final String url;
  final String profileName;
  final bool running;
  final double? fraction;
  final String? detail;
  final String? outputPath;
  final String? error;
  final String? errorDetail;
  final bool audio;
  final String? qualityLabel;
  final String containerLabel;
  final String? destination;
  final int? downloaded;
  final int? total;
  final double? speed;
  final int? eta;
  final String? thumbnailUrl;

  DownloadJob copyWith({
    bool? running,
    double? fraction,
    bool clearFraction = false,
    String? detail,
    String? outputPath,
    String? error,
    bool clearError = false,
    String? errorDetail,
    bool clearErrorDetail = false,
    int? downloaded,
    int? total,
    double? speed,
    int? eta,
    String? thumbnailUrl,
  }) {
    return DownloadJob(
      id: id,
      url: url,
      profileName: profileName,
      running: running ?? this.running,
      fraction: clearFraction ? null : fraction ?? this.fraction,
      detail: detail ?? this.detail,
      outputPath: outputPath ?? this.outputPath,
      error: clearError ? null : error ?? this.error,
      errorDetail: clearErrorDetail ? null : errorDetail ?? this.errorDetail,
      audio: audio,
      qualityLabel: qualityLabel,
      containerLabel: containerLabel,
      destination: destination,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
