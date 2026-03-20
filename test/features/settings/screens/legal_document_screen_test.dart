import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/settings/screens/legal_document_screen.dart';

void main() {
  Widget createSubject(LegalDocumentType type) {
    final router = GoRouter(
      initialLocation: '/legal',
      routes: [
        GoRoute(
          path: '/legal',
          builder: (_, __) => LegalDocumentScreen(type: type),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('LegalDocumentScreen', () {
    group('Privacy Policy', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocumentScreen), findsOneWidget);
      });

      testWidgets('shows correct AppBar title', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        expect(find.text('settings.privacy_policy'), findsOneWidget);
      });

      testWidgets('contains scrollable ListView', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('renders section cards', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows last updated text', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        expect(find.text('legal.last_updated'), findsOneWidget);
      });
    });

    group('Terms of Service', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocumentScreen), findsOneWidget);
      });

      testWidgets('shows correct AppBar title', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();

        expect(find.text('settings.terms'), findsOneWidget);
      });

      testWidgets('contains scrollable ListView', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('renders section cards', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows last updated text', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();

        expect(find.text('legal.last_updated'), findsOneWidget);
      });
    });

    group('Community Guidelines', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocumentScreen), findsOneWidget);
      });

      testWidgets('shows correct AppBar title', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();

        expect(find.text('legal.community_guidelines_title'), findsOneWidget);
      });

      testWidgets('contains scrollable ListView', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('renders section cards', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows last updated text', (tester) async {
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();

        expect(find.text('legal.last_updated'), findsOneWidget);
      });
    });

    group('common rendering', () {
      testWidgets('each document type renders different AppBar title', (
        tester,
      ) async {
        // Privacy Policy
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();
        expect(find.text('settings.privacy_policy'), findsOneWidget);
        expect(find.text('settings.terms'), findsNothing);
        expect(find.text('legal.community_guidelines_title'), findsNothing);

        // Terms of Service
        await tester.pumpWidget(
          createSubject(LegalDocumentType.termsOfService),
        );
        await tester.pumpAndSettle();
        expect(find.text('settings.terms'), findsOneWidget);
        expect(find.text('settings.privacy_policy'), findsNothing);
        expect(find.text('legal.community_guidelines_title'), findsNothing);

        // Community Guidelines
        await tester.pumpWidget(
          createSubject(LegalDocumentType.communityGuidelines),
        );
        await tester.pumpAndSettle();
        expect(find.text('legal.community_guidelines_title'), findsOneWidget);
        expect(find.text('settings.privacy_policy'), findsNothing);
        expect(find.text('settings.terms'), findsNothing);
      });

      testWidgets('body is scrollable', (tester) async {
        await tester.pumpWidget(createSubject(LegalDocumentType.privacyPolicy));
        await tester.pumpAndSettle();

        final listFinder = find.byType(ListView);
        expect(listFinder, findsOneWidget);

        // Verify scrolling does not throw
        await tester.drag(listFinder, const Offset(0, -300));
        await tester.pump();
      });
    });
  });
}
