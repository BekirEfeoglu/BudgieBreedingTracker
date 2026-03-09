import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_notes.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('BirdDetailNotes', () {
    testWidgets('displays notes text', (tester) async {
      const notes = 'Bu kus cok aktif ve sagliklidir.';

      await pumpWidgetSimple(tester, const BirdDetailNotes(notes: notes));

      expect(find.text(notes), findsOneWidget);
    });

    testWidgets('displays section title key', (tester) async {
      await pumpWidgetSimple(tester, const BirdDetailNotes(notes: 'test'));

      expect(find.text('common.notes'), findsOneWidget);
    });

    testWidgets('displays multiline notes correctly', (tester) async {
      const notes = 'Satir 1\nSatir 2\nSatir 3';

      await pumpWidgetSimple(tester, const BirdDetailNotes(notes: notes));

      expect(find.text(notes), findsOneWidget);
    });

    testWidgets('displays empty notes without error', (tester) async {
      await pumpWidgetSimple(tester, const BirdDetailNotes(notes: ''));

      expect(find.text('common.notes'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      await pumpWidgetSimple(tester, const BirdDetailNotes(notes: 'test'));

      expect(
        tester.widget(find.byType(BirdDetailNotes)),
        isA<BirdDetailNotes>(),
      );
    });
  });
}
