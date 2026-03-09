import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG icon widget that reads size and color from [IconTheme] when not
/// explicitly provided. This makes it interchangeable with [Icon] inside
/// shared widgets that wrap their icon child in an [IconTheme].
class AppIcon extends StatelessWidget {
  final String asset;
  final double? size;
  final Color? color;
  final String? semanticsLabel;

  const AppIcon(this.asset, {super.key, this.size, this.color, this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24;
    final effectiveColor = color ?? iconTheme.color;

    return SvgPicture.asset(
      asset,
      width: effectiveSize,
      height: effectiveSize,
      colorFilter: effectiveColor != null
          ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticsLabel,
    );
  }
}
