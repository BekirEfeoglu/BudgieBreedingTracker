import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/auth/recovery_code_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/recovery_codes_dialog.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/test_localization.dart';

class _FakeRecoveryCodeService implements RecoveryCodeService {
  _FakeRecoveryCodeService(this._redeemResult);
  final bool _redeemResult;
  final List<String> redeemedCodes = [];

  @override
  Future<bool> redeem(String code) async {
    redeemedCodes.add(code);
    return _redeemResult;
  }

  @override
  Future<List<String>> generate(String userId) async => const [];

  @override
  Future<int> remainingCount(String userId) async => 0;
}

void main() {
  Widget harness({
    required RecoveryCodeService service,
    required void Function(bool) onResult,
  }) {
    return ProviderScope(
      overrides: [
        recoveryCodeServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showRecoveryCodeRedeemDialog(context);
                  onResult(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows generated codes and copy action', (tester) async {
    await pumpLocalizedApp(
      tester,
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRecoveryCodesDialog(
                  context,
                  codes: const ['ABCDE-FGHIJ', 'KMNPQ-RSTUV'],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('ABCDE-FGHIJ'), findsOneWidget);
    expect(find.text('KMNPQ-RSTUV'), findsOneWidget);
    expect(find.text(l10n('auth.recovery_codes_copy')), findsOneWidget);
    expect(find.text(l10n('auth.recovery_codes_done')), findsOneWidget);
  });

  testWidgets('redeem success pops with true', (tester) async {
    bool? result;
    await pumpLocalizedApp(
      tester,
      harness(
        service: _FakeRecoveryCodeService(true),
        onResult: (r) => result = r,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abcde-fghij');
    await tester.tap(find.text(l10n('auth.recovery_code_submit')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('redeem failure shows error and keeps the dialog open', (
    tester,
  ) async {
    bool? result;
    await pumpLocalizedApp(
      tester,
      harness(
        service: _FakeRecoveryCodeService(false),
        onResult: (r) => result = r,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'wrong-code');
    await tester.tap(find.text(l10n('auth.recovery_code_submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10n('auth.recovery_code_invalid')), findsOneWidget);
    expect(result, isNull, reason: 'dialog stays open on failure');
  });
}
