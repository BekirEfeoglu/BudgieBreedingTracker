import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SettingsOverviewBanner', () {
    testWidgets('renders active count ratio', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsOverviewBanner(activeCount: 7, totalCount: 10),
      ));
      await tester.pump();

      expect(find.text('7/10'), findsOneWidget);
    });

    testWidgets('renders with lastUpdatedAt', (tester) async {
      await tester.pumpWidget(_wrap(
        SettingsOverviewBanner(
          activeCount: 3,
          totalCount: 5,
          lastUpdatedAt: DateTime.now().toUtc(),
        ),
      ));
      await tester.pump();

      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsOverviewBanner(activeCount: 0, totalCount: 0),
      ));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('AccentSettingsSection', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(_wrap(
        const AccentSettingsSection(
          title: 'Test Section',
          description: 'A test description',
          icon: Icon(Icons.settings),
          accentColor: Colors.blue,
          activeCount: 2,
          totalCount: 3,
          children: [Text('Child Widget')],
        ),
      ));
      await tester.pump();

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('A test description'), findsOneWidget);
      expect(find.text('Child Widget'), findsOneWidget);
    });

    testWidgets('renders active count badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const AccentSettingsSection(
          title: 'Section',
          icon: Icon(Icons.settings),
          accentColor: Colors.red,
          activeCount: 1,
          totalCount: 4,
          children: [],
        ),
      ));
      await tester.pump();

      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('renders without description', (tester) async {
      await tester.pumpWidget(_wrap(
        const AccentSettingsSection(
          title: 'Section',
          icon: Icon(Icons.settings),
          accentColor: Colors.green,
          activeCount: 0,
          totalCount: 0,
          children: [],
        ),
      ));
      await tester.pump();

      expect(find.text('Section'), findsOneWidget);
    });

    testWidgets('renders children widgets', (tester) async {
      await tester.pumpWidget(_wrap(
        const AccentSettingsSection(
          title: 'Section',
          icon: Icon(Icons.settings),
          accentColor: Colors.orange,
          activeCount: 0,
          totalCount: 0,
          children: [
            Text('Child 1'),
            Text('Child 2'),
          ],
        ),
      ));
      await tester.pump();

      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });
  });

  group('EnhancedToggleSetting', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Toggle Title',
          subtitle: 'Toggle Subtitle',
          value: true,
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Toggle Title'), findsOneWidget);
      expect(find.text('Toggle Subtitle'), findsOneWidget);
    });

    testWidgets('shows Switch when not updating', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: false,
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows progress indicator when updating', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: true,
          isUpdating: true,
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('shows lastUpdated text when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: true,
          lastUpdated: 'Updated yesterday',
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Updated yesterday'), findsOneWidget);
    });

    testWidgets('shows divider when showDivider is true', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: true,
          showDivider: true,
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('hides divider when showDivider is false', (tester) async {
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: true,
          showDivider: false,
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('calls onChanged when switch is toggled', (tester) async {
      bool? changedValue;
      await tester.pumpWidget(_wrap(
        EnhancedToggleSetting(
          title: 'Title',
          subtitle: 'Sub',
          value: false,
          onChanged: (v) => changedValue = v,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(Switch));
      expect(changedValue, isTrue);
    });
  });

  group('ResetDefaultsButton', () {
    testWidgets('renders button with icon when not loading', (tester) async {
      await tester.pumpWidget(_wrap(
        ResetDefaultsButton(onPressed: () {}),
      ));
      await tester.pump();

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows progress indicator when loading', (tester) async {
      await tester.pumpWidget(_wrap(
        ResetDefaultsButton(isLoading: true, onPressed: () {}),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('button is disabled when loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(_wrap(
        ResetDefaultsButton(
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, isFalse);
    });

    testWidgets('calls onPressed when tapped and not loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(_wrap(
        ResetDefaultsButton(onPressed: () => pressed = true),
      ));
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, isTrue);
    });
  });
}
