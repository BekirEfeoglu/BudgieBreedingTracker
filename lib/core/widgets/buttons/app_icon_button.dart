import 'package:flutter/material.dart';

/// Accessible icon button that guarantees a 48dp minimum tap target
/// (WCAG 2.1 AA target size) and requires a semantic label.
///
/// Use this anywhere you'd reach for [IconButton]. Reserve raw [IconButton]
/// only when you've deliberately verified a smaller target is fine.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
    this.iconSize,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip ?? semanticLabel,
      color: color,
      iconSize: iconSize,
      padding: padding,
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
    );
  }
}
