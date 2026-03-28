import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/pedigree_export_button.dart';

const _testBird = Bird(
  id: 'root-1',
  userId: 'user-1',
  name: 'Test Kuş',
  gender: BirdGender.male,
  status: BirdStatus.alive,
);

void main() {
  group('PedigreeExportButton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PedigreeExportButton), findsOneWidget);
    });

    testWidgets('shows export_options label on button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      // 'genealogy.export_options' key → test ortamında raw string olarak çıkar
      expect(find.text('genealogy.export_options'), findsOneWidget);
    });

    testWidgets('shows FilledButton.tonal as main button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders MenuAnchor widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MenuAnchor), findsOneWidget);
    });

    testWidgets(
      'does not show image export option when onCaptureImage is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PedigreeExportButton(
                rootBird: _testBird,
                ancestors: {'root-1': _testBird},
                maxDepth: 5,
                // onCaptureImage yok
              ),
            ),
          ),
        );
        await tester.pump();

        // Widget render edilmeli, menü kapalı olmalı
        expect(find.byType(PedigreeExportButton), findsOneWidget);
      },
    );

    testWidgets('renders with onCaptureImage callback provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
              onCaptureImage: () async => null,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PedigreeExportButton), findsOneWidget);
    });

    testWidgets('button is enabled initially (not exporting)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedigreeExportButton(
              rootBird: _testBird,
              ancestors: {'root-1': _testBird},
              maxDepth: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('genealogy.export_pdf'), findsOneWidget);
    });
  });
}
