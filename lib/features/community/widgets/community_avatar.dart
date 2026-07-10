import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Circular user avatar with an optional brand gradient ring.
///
/// Shared across the community feed (post header, guide cards, story strip) so
/// the ring + initials fallback stay visually consistent. Falls back to the
/// first letter of [username] when [avatarUrl] is null.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.radius = 20,
    this.ring = true,
    this.ringColors,
  });

  final String username;
  final String? avatarUrl;
  final double radius;
  final bool ring;
  final List<Color>? ringColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    // Cap the decode to roughly the widget's pixel footprint (radius*2 logical
    // × up to ~3x DPR) so a full-resolution source isn't decoded into memory
    // for a small circle.
    final decodeCap = (radius * 6).round();
    final inner = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: hasImage
          ? CachedNetworkImageProvider(
              avatarUrl!,
              maxWidth: decodeCap,
              maxHeight: decodeCap,
            )
          : null,
      child: hasImage
          ? null
          : Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.8,
              ),
            ),
    );

    if (!ring) return inner;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ringColors ?? const [AppColors.primary, AppColors.accent],
        ),
      ),
      child: inner,
    );
  }
}
