import 'package:flutter/material.dart';

/// Budgie login ekranina ozel pastel renk paleti.
///
/// Tema renklerini kullanmak icin [background], [cardSurface] gibi
/// context-aware metodlar kullanilir.
abstract final class BudgieLoginPalette {
  // --- Kus vucudu renkleri ---
  static const maleBudgie = Color(0xFF7EC8C8);
  static const femaleBudgie = Color(0xFFFFD166);
  static const babyBudgie = Color(0xFFA8E6CF);

  // --- Sahne ogeleri ---
  static const leaf = Color(0xFF8BC98B);
  static const branch = Color(0xFF8B6B4A);
  static const branchBark = Color(0xFF6B4F3A);
  static const nestStraw = Color(0xFFD4A373);
  static const nestLine = Color(0xFFBC8A5F);
  static const eggShell = Color(0xFFFFF8F0);
  static const eggSpot = Color(0xFFE8DDD0);
  static const beak = Color(0xFFFFA07A);
  static const eye = Color(0xFF2D2D2D);

  // --- Yanak renkleri ---
  static const maleCheck = Color(0xFF7AB8D4);
  static const femaleCheck = Color(0xFFFFB5C5);

  // --- Dekoratif blob renkleri ---
  static const blobGreen = Color(0xFFE2F0CB);
  static const blobBlue = Color(0xFFD4E8F0);

  // --- Tema uyumlu renkler ---
  static Color background(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFFF4F9F9)
        : Theme.of(context).colorScheme.surface;
  }

  static Color cardSurface(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.92)
        : Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.95);
  }

  static Color cardShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.2);
  }

  static Color bellyOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.25);
  }
}
