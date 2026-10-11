import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:flutter/material.dart';

/// Widget tests have no network. The running app loads the site icon.
bool get sourceFaviconLoads =>
    !Platform.environment.containsKey('FLUTTER_TEST');

class SourceFavicon extends StatelessWidget {
  const SourceFavicon({required this.url, this.size = 16, super.key});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final favicon = sourceFaviconUrl(url);
    final fallback = Icon(Icons.link_rounded, size: size);
    if (favicon == null || !sourceFaviconLoads) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        favicon,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, _) {
          if (frame == null) {
            return fallback;
          }
          return child;
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
