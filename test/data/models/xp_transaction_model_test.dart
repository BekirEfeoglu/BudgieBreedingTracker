@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/xp_transaction_model.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

void main() {
  group('XpTransaction', () {
    test('toJson/fromJson round-trip', () {
      final transaction = XpTransaction(
        id: 'xp-1',
        userId: 'user-1',
        action: XpAction.addBird,
        amount: 50,
        referenceId: 'bird-1',
        createdAt: DateTime.utc(2026, 3, 20),
      );

      final json = transaction.toJson();
      final restored = XpTransaction.fromJson(json);

      expect(restored.id, transaction.id);
      expect(restored.userId, transaction.userId);
      expect(restored.action, transaction.action);
      expect(restored.amount, transaction.amount);
      expect(restored.referenceId, transaction.referenceId);
      expect(restored.createdAt, transaction.createdAt);
    });

    test('deserializes unknown action to unknown', () {
      final json = {
        'id': 'xp-1',
        'user_id': 'user-1',
        'action': 'alien_action',
      };
      final transaction = XpTransaction.fromJson(json);
      expect(transaction.action, XpAction.unknown);
    });

    test('default values are correct', () {
      const transaction = XpTransaction(
        id: 'xp-1',
        userId: 'user-1',
      );
      expect(transaction.action, XpAction.unknown);
      expect(transaction.amount, 0);
      expect(transaction.referenceId, isNull);
      expect(transaction.createdAt, isNull);
    });
  });
}
