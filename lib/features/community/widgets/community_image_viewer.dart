import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Full-screen image viewer with zoom support.
class CommunityImageViewer extends StatelessWidget {
  final String imageUrl;

  const CommunityImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Intentional: image viewer overlay
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Intentional: image viewer overlay
        iconTheme: const IconThemeData(color: Colors.white), // Intentional: image viewer overlay
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (_, __, ___) => Icon(
              LucideIcons.imageOff,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
