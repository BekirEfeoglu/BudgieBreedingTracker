import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';

void main() {
  group('FeedbackCategory', () {
    test('has 3 values', () {
      expect(FeedbackCategory.values.length, 3);
    });

    test('label is non-empty for all values', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });

    test('description is non-empty for all values', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.description, isNotEmpty);
      }
    });

    test('icon returns expected IconData', () {
      expect(FeedbackCategory.bug.icon, LucideIcons.bug);
      expect(FeedbackCategory.feature.icon, LucideIcons.lightbulb);
      expect(FeedbackCategory.general.icon, LucideIcons.messageCircle);
    });

    test('color returns expected Color', () {
      expect(FeedbackCategory.bug.color, AppColors.error);
      expect(FeedbackCategory.feature.color, AppColors.warning);
      expect(FeedbackCategory.general.color, AppColors.budgieBlue);
    });

    test('value returns expected string', () {
      expect(FeedbackCategory.bug.value, 'bug');
      expect(FeedbackCategory.feature.value, 'feature');
      expect(FeedbackCategory.general.value, 'general');
    });
  });

  group('FeedbackStatus', () {
    test('label is non-empty for all values', () {
      for (final status in FeedbackStatus.values) {
        expect(
          status.label,
          isNotEmpty,
          reason: '${status.name}.label is empty',
        );
      }
    });

    test('color returns a Color for all values', () {
      for (final status in FeedbackStatus.values) {
        expect(
          status.color,
          isA<Color>(),
          reason: '${status.name}.color is not a Color',
        );
      }
    });

    test('fromString parses known values correctly', () {
      expect(FeedbackStatus.fromString('open'), FeedbackStatus.open);
      expect(
        FeedbackStatus.fromString('in_progress'),
        FeedbackStatus.inProgress,
      );
      expect(FeedbackStatus.fromString('resolved'), FeedbackStatus.resolved);
      expect(FeedbackStatus.fromString('closed'), FeedbackStatus.closed);
    });

    test('fromString returns unknown for unrecognised value', () {
      expect(
        FeedbackStatus.fromString('anything_else'),
        FeedbackStatus.unknown,
      );
      expect(FeedbackStatus.fromString(''), FeedbackStatus.unknown);
    });
  });

  group('FeedbackEntry.fromJson', () {
    test('parses a complete JSON map correctly', () {
      final json = {
        'id': 'entry-1',
        'type': 'bug',
        'subject': 'App crashes',
        'message': 'It crashes on launch',
        'status': 'open',
        'email': 'user@example.com',
        'admin_response': 'We are looking into it',
        'created_at': '2024-06-01T12:00:00.000Z',
      };

      final entry = FeedbackEntry.fromJson(json);

      expect(entry.id, 'entry-1');
      expect(entry.category, FeedbackCategory.bug);
      expect(entry.subject, 'App crashes');
      expect(entry.message, 'It crashes on launch');
      expect(entry.status, FeedbackStatus.open);
      expect(entry.email, 'user@example.com');
      expect(entry.adminResponse, 'We are looking into it');
      expect(entry.createdAt, DateTime.parse('2024-06-01T12:00:00.000Z'));
    });

    test('null email and adminResponse map to null', () {
      final json = {
        'id': 'entry-2',
        'type': 'general',
        'subject': 'Hello',
        'message': 'Just saying hi',
        'status': 'open',
        'email': null,
        'admin_response': null,
        'created_at': null,
      };

      final entry = FeedbackEntry.fromJson(json);

      expect(entry.email, isNull);
      expect(entry.adminResponse, isNull);
      expect(entry.createdAt, isNull);
    });

    test('unknown type string falls back to general category', () {
      final json = {
        'id': 'entry-3',
        'type': 'nonexistent_type',
        'subject': 'X',
        'message': 'Y',
        'status': 'open',
      };

      final entry = FeedbackEntry.fromJson(json);

      expect(entry.category, FeedbackCategory.general);
    });

    test('unknown status falls back to FeedbackStatus.unknown', () {
      final json = {
        'id': 'entry-4',
        'type': 'feature',
        'subject': 'X',
        'message': 'Y',
        'status': 'weird_status',
      };

      final entry = FeedbackEntry.fromJson(json);

      expect(entry.status, FeedbackStatus.unknown);
    });

    test('missing optional fields do not throw', () {
      final json = {'id': 'entry-5'};

      // Should not throw, only 'id' is strictly required
      expect(() => FeedbackEntry.fromJson(json), returnsNormally);
    });
  });

  group('FeedbackFormState', () {
    test('initial state has default values', () {
      const state = FeedbackFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates fields', () {
      const state = FeedbackFormState();
      final updated = state.copyWith(isLoading: true, isSuccess: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith clears error', () {
      final state = const FeedbackFormState().copyWith(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });
}
