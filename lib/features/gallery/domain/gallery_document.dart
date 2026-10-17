final class GalleryRecord {
  const GalleryRecord({
    required this.jobId,
    this.liked = false,
    this.positionMs = 0,
    this.durationMs,
    this.bytes = 0,
    this.removed = false,
  });

  final String jobId;
  final bool liked;
  final int positionMs;
  final int? durationMs;
  final int bytes;
  final bool removed;

  GalleryRecord copyWith({
    bool? liked,
    int? positionMs,
    int? durationMs,
    bool keepDuration = true,
    int? bytes,
    bool? removed,
  }) {
    return GalleryRecord(
      jobId: jobId,
      liked: liked ?? this.liked,
      positionMs: positionMs ?? this.positionMs,
      durationMs: keepDuration ? durationMs ?? this.durationMs : durationMs,
      bytes: bytes ?? this.bytes,
      removed: removed ?? this.removed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'liked': liked,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'bytes': bytes,
      'removed': removed,
    };
  }

  static GalleryRecord? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final id = raw['jobId'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    final duration = raw['durationMs'];
    return GalleryRecord(
      jobId: id,
      liked: raw['liked'] == true,
      positionMs: raw['positionMs'] is int ? raw['positionMs'] as int : 0,
      durationMs: duration is int ? duration : null,
      bytes: raw['bytes'] is int ? raw['bytes'] as int : 0,
      removed: raw['removed'] == true,
    );
  }
}

final class GalleryDocument {
  const GalleryDocument({this.lastJobId, this.records = const {}});

  final String? lastJobId;
  final Map<String, GalleryRecord> records;

  static const empty = GalleryDocument();

  GalleryRecord recordOf(String jobId) {
    return records[jobId] ?? GalleryRecord(jobId: jobId);
  }

  GalleryDocument upsert(GalleryRecord record) {
    return GalleryDocument(
      lastJobId: lastJobId,
      records: {...records, record.jobId: record},
    );
  }

  GalleryDocument copyWith({String? lastJobId, bool clearLast = false}) {
    return GalleryDocument(
      lastJobId: clearLast ? null : lastJobId ?? this.lastJobId,
      records: records,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 1,
      'lastJobId': lastJobId,
      'records': [for (final record in records.values) record.toJson()],
    };
  }

  static GalleryDocument fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return empty;
    }
    final raw = json['records'];
    final records = <String, GalleryRecord>{};
    if (raw is List) {
      for (final entry in raw) {
        final record = GalleryRecord.fromJson(entry);
        if (record != null) {
          records[record.jobId] = record;
        }
      }
    }
    final last = json['lastJobId'];
    return GalleryDocument(
      lastJobId: last is String && last.isNotEmpty ? last : null,
      records: records,
    );
  }
}
