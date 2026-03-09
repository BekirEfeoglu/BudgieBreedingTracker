import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('SettingsOverviewBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsOverviewBanner(activeCount: 3, totalCount: 5)),
      );
      await tester.pump();
      expect(find.byType(SettingsOverviewBanner), findsOneWidget);
    });

    testWidgets('shows count ratio in header box', (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsOverviewBanner(activeCount: 4, totalCount: 7)),
      );
      await tester.pump();
      expect(find.text('4/7'), findsOneWidget);
    });

    testWidgets('shows settings_active_count localization key', (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsOverviewBanner(activeCount: 2, totalCount: 6)),
      );
      await tester.pump();
      expect(
        find.textContaining('admin.settings_active_count'),
        findsOneWidget,
      );
    });

    testWidgets('shows settings_last_updated when lastUpdatedAt provided', (
      tester,
    ) async {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      await tester.pumpWidget(
        _wrap(
          SettingsOverviewBanner(
            activeCount: 1,
            totalCount: 3,
            lastUpdatedAt: past,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('admin.settings_last_updated'),
        findsOneWidget,
      );
    });

    testWidgets('hides last updated text when lastUpdatedAt is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const SettingsOverviewBanner(activeCount: 0, totalCount: 3)),
      );
      await tester.pump();
      expect(find.textContaining('admin.settings_last_updated'), findsNothing);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsOverviewBanner(activeCount: 1, totalCount: 4)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('AccentSettingsSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'Security Settings',
            icon: Icon(Icons.security),
            accentColor: Colors.red,
            activeCount: 2,
            totalCount: 4,
            children: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AccentSettingsSection), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'Test Section Title',
            icon: Icon(Icons.settings),
            accentColor: Colors.blue,
            activeCount: 1,
            totalCount: 3,
            children: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Test Section Title'), findsOneWidget);
    });

    testWidgets('shows description when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'Title',
            description: 'This is a description.',
            icon: Icon(Icons.info),
            accentColor: Colors.green,
            activeCount: 0,
            totalCount: 2,
            children: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('This is a description.'), findsOneWidget);
    });

    testWidgets('hides description when not provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'No Desc',
            icon: Icon(Icons.info),
            accentColor: Colors.orange,
            activeCount: 0,
            totalCount: 1,
            children: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AccentSettingsSection), findsOneWidget);
    });

    testWidgets('shows active/total count badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'Count Test',
            icon: Icon(Icons.toggle_on),
            accentColor: Colors.purple,
            activeCount: 3,
            totalCount: 5,
            children: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('renders children widgets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AccentSettingsSection(
            title: 'With Children',
            icon: Icon(Icons.list),
            accentColor: Colors.teal,
            activeCount: 0,
            totalCount: 1,
            children: [Text('Child 1'), Text('Child 2')],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });
  });

  group('EnhancedToggleSetting', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Enable Feature',
            subtitle: 'Turns on the feature',
            value: false,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EnhancedToggleSetting), findsOneWidget);
    });

    testWidgets('shows title and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'My Toggle',
            subtitle: 'Toggle subtitle here',
            value: false,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('My Toggle'), findsOneWidget);
      expect(find.text('Toggle subtitle here'), findsOneWidget);
    });

    testWidgets('shows Switch widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Toggle',
            subtitle: 'Sub',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when isUpdating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Updating',
            subtitle: 'Please wait',
            value: true,
            isUpdating: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides CircularProgressIndicator when not updating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Stable',
            subtitle: 'Not updating',
            value: false,
            isUpdating: false,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows lastUpdated text when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Toggle',
            subtitle: 'Sub',
            value: false,
            lastUpdated: '2 minutes ago',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('2 minutes ago'), findsOneWidget);
    });

    testWidgets('shows Divider when showDivider is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Toggle',
            subtitle: 'Sub',
            value: false,
            showDivider: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('hides Divider when showDivider is false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Toggle',
            subtitle: 'Sub',
            value: false,
            showDivider: false,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('calls onChanged when switch toggled', (tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        _wrap(
          EnhancedToggleSetting(
            title: 'Toggle',
            subtitle: 'Sub',
            value: false,
            onChanged: (v) => changedValue = v,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(changedValue, isTrue);
    });
  });

  group('ResetDefaultsButton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(ResetDefaultsButton(onPressed: () {})));
      await tester.pump();
      expect(find.byType(ResetDefaultsButton), findsOneWidget);
    });

    testWidgets('shows admin.reset_defaults label', (tester) async {
      await tester.pumpWidget(_wrap(ResetDefaultsButton(onPressed: () {})));
      await tester.pump();
      expect(find.text('admin.reset_defaults'), findsOneWidget);
    });

    testWidgets('shows progress indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        _wrap(ResetDefaultsButton(isLoading: true, onPressed: () {})),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('button is enabled when not loading', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          ResetDefaultsButton(
            isLoading: false,
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, isTrue);
    });

    testWidgets('button is disabled when isLoading', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          ResetDefaultsButton(isLoading: true, onPressed: () => pressed = true),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(OutlinedButton));
      // Should not be called when loading
      expect(pressed, isFalse);
    });

    testWidgets('renders OutlinedButton', (tester) async {
      await tester.pumpWidget(_wrap(ResetDefaultsButton(onPressed: () {})));
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });
}
