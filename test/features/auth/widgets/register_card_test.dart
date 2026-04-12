import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/register_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController confirmCtrl;
  late GlobalKey<FormState> formKey;

  setUp(() {
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    confirmCtrl = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
  });

  Widget buildSubject({
    bool isLoading = false,
    VoidCallback? onSubmit,
    VoidCallback? onGoogleTap,
    VoidCallback? onAppleTap,
    VoidCallback? onLoginTap,
  }) {
    return SingleChildScrollView(
      child: RegisterCard(
        formKey: formKey,
        nameCtrl: nameCtrl,
        emailCtrl: emailCtrl,
        passwordCtrl: passwordCtrl,
        confirmCtrl: confirmCtrl,
        isLoading: isLoading,
        onSubmit: onSubmit ?? () {},
        onGoogleTap: onGoogleTap ?? () {},
        onAppleTap: onAppleTap ?? () {},
        onLoginTap: onLoginTap ?? () {},
      ),
    );
  }

  group('RegisterCard', () {
    testWidgets('renders card container', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject());

      expect(find.byType(RegisterCard), findsOneWidget);
    });

    testWidgets('displays create account title', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject());

      expect(find.text(resolvedL10n('auth.create_account')), findsOneWidget);
    });

    testWidgets('contains a Form widget', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject());

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('renders without error when isLoading is true', (tester) async {
      // isLoading may trigger animations, so avoid pumpAndSettle
      await EasyLocalization.ensureInitialized();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
          path: 'assets/translations',
          assetLoader: const RealTestAssetLoader(),
          fallbackLocale: const Locale('tr'),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: buildSubject(isLoading: true)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(RegisterCard), findsOneWidget);
    });

    testWidgets('renders without error when isLoading is false', (
      tester,
    ) async {
      await pumpTranslatedWidget(tester, buildSubject(isLoading: false));

      expect(find.byType(RegisterCard), findsOneWidget);
    });

    testWidgets('card has rounded border decoration', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject());

      final container = tester.widget<Container>(
        find
            .ancestor(of: find.byType(Column), matching: find.byType(Container))
            .first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(28));
      expect(container.padding, const EdgeInsets.all(AppSpacing.xxl));
    });
  });
}
