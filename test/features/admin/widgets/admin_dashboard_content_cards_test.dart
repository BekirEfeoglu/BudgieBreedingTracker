import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_content.dart';

void main() {
  group('DashboardStatCard', () {
    testWidgets('should_render_without_crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: DashboardStatCard(
                icon: Icon(Icons.person),
                label: 'Test Label',
                value: '42',
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DashboardStatCard), findsOneWidget);
    });

    testWidgets('should_show_label_text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: DashboardStatCard(
                icon: Icon(Icons.person),
                label: 'Users',
                value: '10',
                color: Colors.green,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Users'), findsOneWidget);
    });

    testWidgets('should_animate_numeric_value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: DashboardStatCard(
                icon: Icon(Icons.star),
                label: 'Stars',
                value: '50',
                color: Colors.amber,
              ),
            ),
          ),
        ),
      );
      // After animation completes
      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should_show_non_numeric_value_directly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: DashboardStatCard(
                icon: Icon(Icons.info),
                label: 'Status',
                value: 'Active',
                color: Colors.teal,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('DashboardQuickActionButton', () {
    testWidgets('should_render_with_icon_and_label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQuickActionButton(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should_call_onTap_when_pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQuickActionButton(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Settings'));
      expect(tapped, isTrue);
    });
  });
}
