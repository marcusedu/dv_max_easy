import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class GalleryRail extends StatelessWidget {
  const GalleryRail({
    required this.liked,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
    required this.onLike,
    required this.onShare,
    required this.onInfo,
    required this.onDelete,
    super.key,
  });

  final bool liked;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onInfo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RailButton(
            tooltip: l10n.galleryPrevious,
            icon: Icons.keyboard_arrow_up_rounded,
            onPressed: canPrevious ? onPrevious : null,
          ),
          const SizedBox(height: AppSpacing.s),
          _RailButton(
            tooltip: liked ? l10n.galleryUnlike : l10n.galleryLike,
            icon: liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? const Color(0xFFFF2D55) : Colors.white,
            onPressed: onLike,
          ),
          _RailButton(
            tooltip: l10n.galleryShare,
            icon: Icons.ios_share,
            onPressed: onShare,
          ),
          _RailButton(
            tooltip: l10n.galleryInfo,
            icon: Icons.info_outline,
            onPressed: onInfo,
          ),
          const SizedBox(height: AppSpacing.l),
          _RailButton(
            tooltip: l10n.galleryDelete,
            icon: Icons.delete_outline,
            onPressed: onDelete,
          ),
          const SizedBox(height: AppSpacing.s),
          _RailButton(
            tooltip: l10n.galleryNext,
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: canNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return PressableScale(
      enabled: enabled,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: enabled ? color : Colors.white.withValues(alpha: 0.28),
          size: 26,
        ),
      ),
    );
  }
}
