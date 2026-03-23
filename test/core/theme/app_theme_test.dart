import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme.light()', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.light();
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('brightness is light', () {
      expect(theme.brightness, Brightness.light);
    });

    test('has a color scheme', () {
      expect(theme.colorScheme, isNotNull);
    });

    test('color scheme brightness is light', () {
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('has a primary color in color scheme', () {
      expect(theme.colorScheme.primary, isA<Color>());
    });

    test('has a secondary color in color scheme', () {
      expect(theme.colorScheme.secondary, isA<Color>());
    });

    test('has an error color in color scheme', () {
      expect(theme.colorScheme.error, isA<Color>());
    });

    test('has a text theme', () {
      expect(theme.textTheme, isNotNull);
    });

    group('appBar theme', () {
      test('centerTitle is true', () {
        expect(theme.appBarTheme.centerTitle, isTrue);
      });

      test('elevation is 0', () {
        expect(theme.appBarTheme.elevation, 0);
      });

      test('scrolledUnderElevation is 1', () {
        expect(theme.appBarTheme.scrolledUnderElevation, 1);
      });
    });

    group('card theme', () {
      test('elevation is 0', () {
        expect(theme.cardTheme.elevation, 0);
      });

      test('shape is RoundedRectangleBorder', () {
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('card border radius is 12', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.circular(12),
        );
      });
    });

    group('input decoration theme', () {
      test('is filled', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
      });

      test('has fill color', () {
        expect(theme.inputDecorationTheme.fillColor, isNotNull);
      });

      test('border is OutlineInputBorder', () {
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      });

      test('enabled border is OutlineInputBorder', () {
        expect(
          theme.inputDecorationTheme.enabledBorder,
          isA<OutlineInputBorder>(),
        );
      });

      test('focused border is OutlineInputBorder', () {
        expect(
          theme.inputDecorationTheme.focusedBorder,
          isA<OutlineInputBorder>(),
        );
      });

      test('content padding is defined', () {
        expect(theme.inputDecorationTheme.contentPadding, isNotNull);
      });
    });

    group('elevated button theme', () {
      test('style is defined', () {
        expect(theme.elevatedButtonTheme.style, isNotNull);
      });
    });

    group('navigation bar theme', () {
      test('height is 65', () {
        expect(theme.navigationBarTheme.height, 65);
      });

      test('label behavior is alwaysShow', () {
        expect(
          theme.navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
      });

      test('indicator color is set', () {
        expect(theme.navigationBarTheme.indicatorColor, isNotNull);
      });
    });

    group('bottom sheet theme', () {
      test('shows drag handle', () {
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });

      test('shape is rounded rectangle', () {
        expect(theme.bottomSheetTheme.shape, isA<RoundedRectangleBorder>());
      });
    });
  });

  group('AppTheme.dark()', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.dark();
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('brightness is dark', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('color scheme brightness is dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('has a color scheme', () {
      expect(theme.colorScheme, isNotNull);
    });

    test('has a text theme', () {
      expect(theme.textTheme, isNotNull);
    });

    group('appBar theme', () {
      test('centerTitle is true', () {
        expect(theme.appBarTheme.centerTitle, isTrue);
      });

      test('elevation is 0', () {
        expect(theme.appBarTheme.elevation, 0);
      });
    });

    group('card theme', () {
      test('elevation is 0', () {
        expect(theme.cardTheme.elevation, 0);
      });

      test('shape is RoundedRectangleBorder', () {
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('input decoration theme', () {
      test('is filled', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
      });

      test('has fill color', () {
        expect(theme.inputDecorationTheme.fillColor, isNotNull);
      });
    });

    group('navigation bar theme', () {
      test('height is 65', () {
        expect(theme.navigationBarTheme.height, 65);
      });

      test('label behavior is alwaysShow', () {
        expect(
          theme.navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
      });
    });

    group('bottom sheet theme', () {
      test('shows drag handle', () {
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });
    });
  });

  group('AppTheme — light vs dark differences', () {
    test('light and dark themes have different brightness', () {
      expect(AppTheme.light().brightness, isNot(AppTheme.dark().brightness));
    });

    test('light and dark have different color scheme brightness', () {
      expect(
        AppTheme.light().colorScheme.brightness,
        isNot(AppTheme.dark().colorScheme.brightness),
      );
    });

    test('light and dark have different surface colors', () {
      expect(
        AppTheme.light().colorScheme.surface,
        isNot(AppTheme.dark().colorScheme.surface),
      );
    });

    test('light and dark input decoration fill colors differ', () {
      expect(
        AppTheme.light().inputDecorationTheme.fillColor,
        isNot(AppTheme.dark().inputDecorationTheme.fillColor),
      );
    });
  });

  group('AppTheme — consistency between light and dark', () {
    test('both themes use Material 3', () {
      expect(AppTheme.light().useMaterial3, isTrue);
      expect(AppTheme.dark().useMaterial3, isTrue);
    });

    test('both themes have same appBar elevation', () {
      expect(
        AppTheme.light().appBarTheme.elevation,
        AppTheme.dark().appBarTheme.elevation,
      );
    });

    test('both themes have same card elevation', () {
      expect(
        AppTheme.light().cardTheme.elevation,
        AppTheme.dark().cardTheme.elevation,
      );
    });

    test('both themes have same navigation bar height', () {
      expect(
        AppTheme.light().navigationBarTheme.height,
        AppTheme.dark().navigationBarTheme.height,
      );
    });

    test('both themes have centerTitle on appBar', () {
      expect(AppTheme.light().appBarTheme.centerTitle, isTrue);
      expect(AppTheme.dark().appBarTheme.centerTitle, isTrue);
    });
  });
}
