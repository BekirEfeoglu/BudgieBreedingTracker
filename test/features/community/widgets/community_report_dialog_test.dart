import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_report_dialog.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('showCommunityReportDialog', () {
    testWidgets('displays dialog with given title', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportDialog(context, title: 'Report Post');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Report Post'), findsOneWidget);
    });

    testWidgets('shows all reasons except unknown', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportDialog(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final options = find.byType(SimpleDialogOption);
      expect(options, findsNWidgets(5));
      expect(find.text(resolvedL10n('community.report_reason_spam')), findsOneWidget);
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
      expect(find.text(resolvedL10n('community.report_reason_other')), findsOneWidget);
    });

    testWidgets('renders as a SimpleDialog', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityReportDialog(context, title: 'Report');
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
    });

    testWidgets('tapping a reason returns selected value', (tester) async {
      CommunityReportReason? result;

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityReportDialog(
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

      // Tap the first SimpleDialogOption (spam)
      await tester.tap(find.byType(SimpleDialogOption).first);
      await tester.pumpAndSettle();

      expect(result, CommunityReportReason.spam);
    });

    testWidgets('dismissing dialog returns null', (tester) async {
      CommunityReportReason? result = CommunityReportReason.spam;

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityReportDialog(
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

      // Tap outside the dialog to dismiss
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
