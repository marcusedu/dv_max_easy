final class TargetFolderSlot {
  const TargetFolderSlot({
    required this.slotNumber,
    required this.label,
    required this.path,
    this.iconName,
  });

  final int slotNumber;
  final String label;
  final String path;
  final String? iconName;

  bool get isConfigured => path.trim().isNotEmpty;

  TargetFolderSlot copyWith({
    int? slotNumber,
    String? label,
    String? path,
    String? iconName,
  }) {
    return TargetFolderSlot(
      slotNumber: slotNumber ?? this.slotNumber,
      label: label ?? this.label,
      path: path ?? this.path,
      iconName: iconName ?? this.iconName,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotNumber': slotNumber,
    'label': label,
    'path': path,
    if (iconName != null) 'iconName': iconName,
  };

  factory TargetFolderSlot.fromJson(Map<String, dynamic> json) {
    return TargetFolderSlot(
      slotNumber: json['slotNumber'] as int? ?? 1,
      label: json['label'] as String? ?? '',
      path: json['path'] as String? ?? '',
      iconName: json['iconName'] as String?,
    );
  }
}

List<TargetFolderSlot> createDefaultSlots({
  required String picturesPath,
  required String moviesPath,
  required String musicPath,
  required String documentsPath,
}) {
  return [
    TargetFolderSlot(
      slotNumber: 1,
      label: 'Fotos',
      path: picturesPath,
      iconName: 'photo',
    ),
    TargetFolderSlot(
      slotNumber: 2,
      label: 'Vídeos',
      path: moviesPath,
      iconName: 'movie',
    ),
    TargetFolderSlot(
      slotNumber: 3,
      label: 'Músicas',
      path: musicPath,
      iconName: 'music',
    ),
    TargetFolderSlot(
      slotNumber: 4,
      label: 'Documentos',
      path: documentsPath,
      iconName: 'doc',
    ),
    const TargetFolderSlot(slotNumber: 5, label: 'Slot 5', path: ''),
    const TargetFolderSlot(slotNumber: 6, label: 'Slot 6', path: ''),
    const TargetFolderSlot(slotNumber: 7, label: 'Slot 7', path: ''),
    const TargetFolderSlot(slotNumber: 8, label: 'Slot 8', path: ''),
    const TargetFolderSlot(slotNumber: 9, label: 'Slot 9', path: ''),
  ];
}
