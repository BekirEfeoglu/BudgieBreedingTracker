@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_edit_sheet.dart';

import '../../../helpers/test_localization.dart';

CommunityPost _testPost({
  String id = 'post-1',
  String userId = 'me',
  String content = 'Original content',
}) {
  return CommunityPost(id: id, userId: userId, content: content);
}

void main() {
  group('showCommunityPostEditSheet', () {
    testWidgets('shows title and prefilled content', (tester) async {
      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showCommunityPostEditSheet(context, _testPost());
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text(resolvedL10n('community.edit_post_title')),
        findsOneWidget,
      );
      expect(find.text('Original content'), findsOneWidget);
      expect(find.text(resolvedL10n('common.save')), findsOneWidget);
    });

    testWidgets(
      'tapping save without editing returns null (unchanged content)',
      (tester) async {
        String? result = 'sentinel';

        await pumpTranslatedWidget(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCommunityPostEditSheet(
                  context,
                  _testPost(content: 'Original content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(resolvedL10n('common.save')));
        await tester.pumpAndSettle();

        expect(result, isNull);
      },
    );

    testWidgets('tapping save with only whitespace changes returns null', (
      tester,
    ) async {
      String? result = 'sentinel';

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityPostEditSheet(
                context,
                _testPost(content: 'Original content'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Append trailing whitespace only — trimmed text still equals original.
      await tester.enterText(find.byType(TextField), 'Original content   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text(resolvedL10n('common.save')));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('tapping save after clearing content returns null', (
      tester,
    ) async {
      String? result = 'sentinel';

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityPostEditSheet(
                context,
                _testPost(content: 'Original content'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text(resolvedL10n('common.save')));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('tapping save with changed content returns trimmed text', (
      tester,
    ) async {
      String? result;

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityPostEditSheet(
                context,
                _testPost(content: 'Original content'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '  Updated content here  ',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(resolvedL10n('common.save')));
      await tester.pumpAndSettle();

      expect(result, 'Updated content here');
    });

    testWidgets('dismissing the sheet returns null', (tester) async {
      String? result = 'sentinel';

      await pumpTranslatedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showCommunityPostEditSheet(
                context,
                _testPost(content: 'Original content'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // Drag down to dismiss without saving — same dismissal pattern as
      // community_report_sheet_test.dart's "dismissing sheet returns null".
      await tester.drag(find.byType(BottomSheet), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(result, isNull);
    });
  });
}
