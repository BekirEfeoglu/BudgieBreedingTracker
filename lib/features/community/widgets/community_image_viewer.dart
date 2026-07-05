import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/buttons/app_icon_button.dart';

/// Full-screen, swipeable image viewer with zoom support.
///
/// Renders every image in [imageUrls] in a horizontally swipeable [PageView]
/// starting at [initialIndex], so all images in a multi-image post are
/// reachable — the feed collage only shows the first three cells, but opening
/// any cell lets the user page through the full set.
class CommunityImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const CommunityImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<CommunityImageViewer> createState() => _CommunityImageViewerState();
}

class _CommunityImageViewerState extends State<CommunityImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final lastIndex = widget.imageUrls.isEmpty ? 0 : widget.imageUrls.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, lastIndex);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;

    return Scaffold(
      backgroundColor: Colors.black, // Intentional: image viewer overlay
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Intentional: image viewer overlay
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Intentional: image viewer overlay
        title: count > 1
            ? Text(
                '${_currentIndex + 1} / $count',
                style: const TextStyle(
                  color: Colors.white, // Intentional: image viewer overlay
                  fontSize: 16,
                ),
              )
            : null,
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.x),
            semanticLabel: 'common.close'.tr(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: count == 0
          ? Center(
              child: Icon(
                LucideIcons.imageOff,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth:
                        (MediaQuery.sizeOf(context).width *
                                MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    memCacheHeight:
                        (MediaQuery.sizeOf(context).height *
                                MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    errorWidget: (_, __, ___) => Icon(
                      LucideIcons.imageOff,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
