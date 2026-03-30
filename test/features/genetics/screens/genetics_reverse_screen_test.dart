import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_reverse_screen.dart';

Widget _wrap() {
  return const ProviderScope(child: MaterialApp(home: GeneticsReverseScreen()));
}

void main() {
  group('GeneticsReverseScreen', () {
    testWidgets('shows empty-state prompt before any calculation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text(l10n('genetics.reverse_no_selection')), findsOneWidget);
    });

    testWidgets('renders loading state safely after starting calculation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      await tester.tap(find.text(l10n('genetics.find_parents')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      expect(find.byType(GeneticsReverseScreen), findsOneWidget);
    });
  });
}
