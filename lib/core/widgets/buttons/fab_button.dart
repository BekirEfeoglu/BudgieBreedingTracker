import 'package:flutter/material.dart';

class FabButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Object? heroTag;

  const FabButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // A null tag disables the implicit Hero. Multiple StatefulShellRoute
      // branches stay mounted together, so Flutter's default FAB tag can
      // otherwise collide during any route transition.
      heroTag: heroTag,
      onPressed: onPressed,
      tooltip: tooltip,
      child: icon,
    );
  }
}
