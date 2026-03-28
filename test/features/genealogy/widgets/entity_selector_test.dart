import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/entity_selector.dart';

Bird _makeBird({
  required String id,
  required String name,
  String? ringNumber,
}) => Bird(
  id: id,
  userId: 'user-1',
  name: name,
  gender: BirdGender.male,
  status: BirdStatus.alive,
  ringNumber: ringNumber,
);

// EntitySelector Expanded gerektiriyor, dolayısıyla sabit boyutlu bir
// Scaffold + Column içinde sarmalanması gerekiyor.
Widget _wrap({
  required List<Bird> birds,
  required List<Chick> chicks,
  GenealogySelection? selection,
  ValueChanged<GenealogySelection?>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: EntitySelector(
              birds: birds,
              chicks: chicks,
              selection: selection,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('EntitySelector', () {
    testWidgets('renders TextField for search input', (tester) async {
      await tester.pumpWidget(_wrap(birds: [], chicks: []));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows no_results when both lists are empty and no query', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(birds: [], chicks: []));
      await tester.pump();

      expect(find.text('common.no_results'), findsOneWidget);
    });

    testWidgets('shows bird names when birds list is provided', (tester) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Mavi Muhabbet'),
        _makeBird(id: 'b2', name: 'Yeşil Muhabbet'),
      ];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      expect(find.text('Mavi Muhabbet'), findsOneWidget);
      expect(find.text('Yeşil Muhabbet'), findsOneWidget);
    });

    testWidgets('shows chick name when chicks list is provided', (
      tester,
    ) async {
      const chick = Chick(
        id: 'c1',
        userId: 'user-1',
        name: 'Sarı Civciv',
        gender: BirdGender.female,
      );

      await tester.pumpWidget(_wrap(birds: [], chicks: [chick]));
      await tester.pump();

      expect(find.text('Sarı Civciv'), findsOneWidget);
    });

    testWidgets('filters birds when search query is entered', (tester) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Mavi Kuş'),
        _makeBird(id: 'b2', name: 'Yeşil Kuş'),
      ];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      // Arama alanına gir
      await tester.enterText(find.byType(TextField), 'Mavi');
      await tester.pump();

      expect(find.text('Mavi Kuş'), findsOneWidget);
      expect(find.text('Yeşil Kuş'), findsNothing);
    });

    testWidgets('shows no_results when search query matches nothing', (
      tester,
    ) async {
      final birds = [_makeBird(id: 'b1', name: 'Mavi Kuş')];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'xyz_bulunamaz');
      await tester.pump();

      expect(find.text('common.no_results'), findsOneWidget);
    });

    testWidgets('calls onChanged when a bird tile is tapped', (tester) async {
      GenealogySelection? selected;
      final birds = [_makeBird(id: 'b1', name: 'Seçilecek Kuş')];

      await tester.pumpWidget(
        _wrap(birds: birds, chicks: [], onChanged: (sel) => selected = sel),
      );
      await tester.pump();

      await tester.tap(find.text('Seçilecek Kuş'));
      await tester.pump();

      expect(selected, (id: 'b1', isChick: false));
    });

    testWidgets('calls onChanged with chick selection when chick tapped', (
      tester,
    ) async {
      GenealogySelection? selected;
      const chick = Chick(
        id: 'c1',
        userId: 'user-1',
        name: 'Seçilecek Yavru',
        gender: BirdGender.male,
      );

      await tester.pumpWidget(
        _wrap(birds: [], chicks: [chick], onChanged: (sel) => selected = sel),
      );
      await tester.pump();

      await tester.tap(find.text('Seçilecek Yavru'));
      await tester.pump();

      expect(selected, (id: 'c1', isChick: true));
    });

    testWidgets('shows ring number as subtitle when bird has ring', (
      tester,
    ) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Ring Kuş', ringNumber: 'TR-789'),
      ];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      expect(find.text('TR-789'), findsOneWidget);
    });

    testWidgets('shows clear button (X) when query is non-empty', (
      tester,
    ) async {
      final birds = [_makeBird(id: 'b1', name: 'Kuş')];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();

      // Temizle (X) butonu görünmeli
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('clears query when clear button is tapped', (tester) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Mavi Kuş'),
        _makeBird(id: 'b2', name: 'Kırmızı Kuş'),
      ];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Mavi');
      await tester.pump();

      // X butonuna tap
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Her iki kuş da tekrar görünmeli
      expect(find.text('Mavi Kuş'), findsOneWidget);
      expect(find.text('Kırmızı Kuş'), findsOneWidget);
    });

    testWidgets('shows selected indicator when selection matches a bird', (
      tester,
    ) async {
      const sel = (id: 'b1', isChick: false);
      final birds = [_makeBird(id: 'b1', name: 'Seçili Kuş')];

      await tester.pumpWidget(_wrap(birds: birds, chicks: [], selection: sel));
      await tester.pump();

      // Seçili ListTile'da check ikonu var
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      final tile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(tile.selected, isTrue);
    });

    testWidgets('renders birds.title section header when birds present', (
      tester,
    ) async {
      final birds = [_makeBird(id: 'b1', name: 'Bir Kuş')];

      await tester.pumpWidget(_wrap(birds: birds, chicks: []));
      await tester.pump();

      // SliverPersistentHeader → 'birds.title' raw key
      expect(find.text('birds.title'), findsOneWidget);
    });

    testWidgets('renders chicks.title section header when chicks present', (
      tester,
    ) async {
      const chick = Chick(
        id: 'c1',
        userId: 'user-1',
        name: 'Bir Yavru',
        gender: BirdGender.unknown,
      );

      await tester.pumpWidget(_wrap(birds: [], chicks: [chick]));
      await tester.pump();

      expect(find.text('chicks.title'), findsOneWidget);
    });
  });
}
