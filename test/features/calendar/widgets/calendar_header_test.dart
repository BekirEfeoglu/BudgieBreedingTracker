import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_header.dart';

class _MockAssetLoader extends AssetLoader {
  const _MockAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

class _FakeDisplayedMonthNotifier extends DisplayedMonthNotifier {
  _FakeDisplayedMonthNotifier(this._initial);
  final DateTime _initial;
  @override
  DateTime build() => _initial;
}

class _FakeSelectedDateNotifier extends SelectedDateNotifier {
  @override
  DateTime build() => DateTime(2024, 3, 15);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget buildSubject({DateTime? displayedMonth}) {
    final month = displayedMonth ?? DateTime(2024, 3);
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _MockAssetLoader(),
      child: ProviderScope(
        overrides: [
          displayedMonthProvider.overrideWith(
            () => _FakeDisplayedMonthNotifier(month),
          ),
          selectedDateProvider.overrideWith(() => _FakeSelectedDateNotifier()),
        ],
        child: const MaterialApp(home: Scaffold(body: CalendarHeader())),
      ),
    );
  }

  group('CalendarHeader', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(CalendarHeader), findsOneWidget);
    });

    testWidgets('renders title text in the center', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // A Text widget with the month label should be present.
      expect(
        find.descendant(
          of: find.byType(CalendarHeader),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows two IconButtons (previous and next month)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('shows chevron left icon for previous month', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    });

    testWidgets('shows chevron right icon for next month', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('shows a tappable InkWell in the center (today button)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // IconButton (M3) also creates InkWell internally, so expect at least 1
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping next-month button changes displayed month forward', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(displayedMonth: DateTime(2024, 3)));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarHeader)),
      );
      // Month starts as March 2024
      expect(container.read(displayedMonthProvider).month, 3);

      // Second IconButton is next-month
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      expect(container.read(displayedMonthProvider).month, 4);
    });

    testWidgets('tapping previous-month button changes displayed month back', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(displayedMonth: DateTime(2024, 3)));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarHeader)),
      );
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      expect(container.read(displayedMonthProvider).month, 2);
    });

    testWidgets('tapping title area resets displayed month to today', (
      tester,
    ) async {
      // Start with a past month so "go to today" has an observable effect.
      await tester.pumpWidget(buildSubject(displayedMonth: DateTime(2023, 1)));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarHeader)),
      );
      expect(container.read(displayedMonthProvider).year, 2023);

      // Tap the InkWell that contains the Text widget (month label).
      // IconButton InkWells do not contain a direct Text child.
      final titleInkWell = find.ancestor(
        of: find.byType(Text),
        matching: find.byType(InkWell),
      );
      await tester.tap(titleInkWell.first);
      await tester.pump();

      final updated = container.read(displayedMonthProvider);
      final now = DateTime.now();
      expect(updated.month, now.month);
      expect(updated.year, now.year);
    });
  });
}
