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
    home: Scaffold(
      body: Center(child: child),
    ),
  );

  if (surfaceSize != null) {
    return MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: SizedBox(
        width: surfaceSize.width,
        height: surfaceSize.height,
        child: widget,
      ),
    );
  }

  return widget;
}
