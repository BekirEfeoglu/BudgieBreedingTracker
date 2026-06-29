import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';

/// Wraps a widget in MaterialApp with the app's theme for golden tests.
/// Use [surfaceSize] to constrain the rendering area.
Widget buildGoldenWidget(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  Size? surfaceSize,
}) {
  final widget = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );

  if (surfaceSize != null) {
    return MediaQuery(
      // disableAnimations keeps reduce-motion-aware decorative animations
      // (pulse/shimmer/scanner/slide-fade) static. This explicit MediaQueryData
      // would otherwise default it to false, shadowing the global test config
      // and hanging pumpAndSettle on perpetual animations.
      data: MediaQueryData(size: surfaceSize, disableAnimations: true),
      child: SizedBox(
        width: surfaceSize.width,
        height: surfaceSize.height,
        child: widget,
      ),
    );
  }

  return widget;
}
