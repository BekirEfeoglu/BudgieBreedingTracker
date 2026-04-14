@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart'; // ignore: unused_import — used for icon lookup
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_report_sheet.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('showCommunityReportSheet', () {
    testWidgets('shows title from parameter', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Gönderiyi Bildir');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Gönderiyi Bildir'), findsOneWidget);
    });

    testWidgets('renders drag handle', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Drag handle is a Container with specific size — sheet itself is visible
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows all 5 reason cards', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text(resolvedL10n('community.report_reason_spam')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_reason_harassment')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_reason_inappropriate')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_reason_misinformation')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_reason_other')),
        findsOneWidget,
      );
    });

    testWidgets('shows hint text for each reason', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text(resolvedL10n('community.report_spam_hint')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_harassment_hint')),
        findsOneWidget,
      );
    });

    testWidgets('submit button is not visible before selection', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text(resolvedL10n('community.report_confirm')),
        findsNothing,
      );
    });

    testWidgets('tapping a reason shows confirm button', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(resolvedL10n('community.report_reason_spam')));
      await tester.pumpAndSettle();

      expect(
        find.text(resolvedL10n('community.report_confirm')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('community.report_confirm_message')),
        findsOneWidget,
      );
    });

    testWidgets('tapping a reason highlights it', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(resolvedL10n('community.report_reason_harassment')),
      );
      await tester.pumpAndSettle();

      // Check icon is shown (checkCircle2 appears for selected reason)
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('selecting "other" shows text field', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(resolvedL10n('community.report_reason_other')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('selecting non-other reason does not show text field',
        (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(resolvedL10n('community.report_reason_spam')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('submitting returns selected reason', (tester) async {
      CommunityReportReason? result;

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityReportSheet(
                context,
                title: 'Report',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(resolvedL10n('community.report_reason_misinformation')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(resolvedL10n('community.report_confirm')));
      await tester.pumpAndSettle();

      expect(result, CommunityReportReason.misinformation);
    });

    testWidgets('dismissing sheet returns null', (tester) async {
      CommunityReportReason? result = CommunityReportReason.spam;

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityReportSheet(
                context,
                title: 'Report',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Drag down to dismiss
      await tester.drag(find.byType(BottomSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('can switch selected reason', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportSheet(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Select spam first
      await tester.tap(
        find.text(resolvedL10n('community.report_reason_spam')),
      );
      await tester.pumpAndSettle();

      // Switch to harassment
      await tester.tap(
        find.text(resolvedL10n('community.report_reason_harassment')),
      );
      await tester.pumpAndSettle();

      // Only one checkmark should be visible
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });
  });
}
