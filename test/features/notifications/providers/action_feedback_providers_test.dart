import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

void main() {
  setUp(() {
    ActionFeedbackService.resetForTesting();
  });

  group('ActionFeedback', () {
    test('copyWith updates isRead', () {
      final feedback = ActionFeedback(
        id: '1',
        message: 'test',
        type: ActionFeedbackType.success,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(feedback.isRead, isFalse);

      final updated = feedback.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(updated.id, '1');
      expect(updated.message, 'test');
      expect(updated.type, ActionFeedbackType.success);
    });

    test('copyWith preserves optional fields', () {
      final feedback = ActionFeedback(
        id: '1',
        message: 'test',
        type: ActionFeedbackType.info,
        createdAt: DateTime(2024, 1, 1),
        actionRoute: '/birds',
        actionLabel: 'Go to birds',
      );
      final updated = feedback.copyWith(isRead: true);
      expect(updated.actionRoute, '/birds');
      expect(updated.actionLabel, 'Go to birds');
    });
  });

  group('ActionFeedbackService', () {
    test('show broadcasts feedback to stream', () async {
      final feedbacks = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(feedbacks.add);
      addTearDown(sub.cancel);

      ActionFeedbackService.show('hello');

      expect(feedbacks, hasLength(1));
      expect(feedbacks.first.message, 'hello');
      expect(feedbacks.first.type, ActionFeedbackType.success);
    });

    test('show with custom type and action route', () {
      final feedbacks = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(feedbacks.add);
      addTearDown(sub.cancel);

      ActionFeedbackService.show(
        'error occurred',
        type: ActionFeedbackType.error,
        actionRoute: '/settings',
        actionLabel: 'Fix it',
      );

      expect(feedbacks.first.type, ActionFeedbackType.error);
      expect(feedbacks.first.actionRoute, '/settings');
      expect(feedbacks.first.actionLabel, 'Fix it');
    });

    test('show assigns unique ids', () {
      final feedbacks = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(feedbacks.add);
      addTearDown(sub.cancel);

      ActionFeedbackService.show('first');
      ActionFeedbackService.show('second');

      expect(feedbacks[0].id, isNot(feedbacks[1].id));
    });

    test('resetForTesting isolates streams', () {
      final firstBatch = <ActionFeedback>[];
      final sub1 = ActionFeedbackService.stream.listen(firstBatch.add);

      ActionFeedbackService.show('before reset');
      expect(firstBatch, hasLength(1));

      ActionFeedbackService.resetForTesting();
      // Old listener should not receive new events
      ActionFeedbackService.show('after reset');
      expect(firstBatch, hasLength(1));

      sub1.cancel();
    });

    test('show does nothing after stream is closed', () {
      ActionFeedbackService.resetForTesting();
      // This should not throw
      ActionFeedbackService.show('safe call');
    });
  });

  group('ActionFeedbackNotifier', () {
    test('starts with empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final feedbacks = container.read(actionFeedbackProvider);
      expect(feedbacks, isEmpty);
    });

    test('accumulates feedbacks from service stream', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Force the provider to build and start listening
      container.listen(actionFeedbackProvider, (_, __) {});

      ActionFeedbackService.show('msg1');
      ActionFeedbackService.show('msg2');

      final feedbacks = container.read(actionFeedbackProvider);
      expect(feedbacks, hasLength(2));
      // Newest first
      expect(feedbacks.first.message, 'msg2');
      expect(feedbacks.last.message, 'msg1');
    });

    test('caps at 20 items with FIFO eviction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      for (var i = 0; i < 25; i++) {
        ActionFeedbackService.show('msg-$i');
      }

      final feedbacks = container.read(actionFeedbackProvider);
      expect(feedbacks, hasLength(20));
      // Most recent should be msg-24
      expect(feedbacks.first.message, 'msg-24');
    });

    test('markAllRead marks all feedbacks as read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      ActionFeedbackService.show('a');
      ActionFeedbackService.show('b');

      container.read(actionFeedbackProvider.notifier).markAllRead();

      final feedbacks = container.read(actionFeedbackProvider);
      expect(feedbacks.every((f) => f.isRead), isTrue);
    });

    test('markAllRead is no-op when all already read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      ActionFeedbackService.show('a');
      final notifier = container.read(actionFeedbackProvider.notifier);
      notifier.markAllRead();

      final before = container.read(actionFeedbackProvider);
      notifier.markAllRead();
      final after = container.read(actionFeedbackProvider);

      // Should be identical reference (no state change)
      expect(identical(before, after), isTrue);
    });

    test('clearAll removes all feedbacks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      ActionFeedbackService.show('a');
      ActionFeedbackService.show('b');

      container.read(actionFeedbackProvider.notifier).clearAll();

      expect(container.read(actionFeedbackProvider), isEmpty);
    });

    test('clearAll is no-op when already empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      final before = container.read(actionFeedbackProvider);
      container.read(actionFeedbackProvider.notifier).clearAll();
      final after = container.read(actionFeedbackProvider);

      expect(identical(before, after), isTrue);
    });
  });

  group('unreadFeedbackCountProvider', () {
    test('returns 0 when empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});

      expect(container.read(unreadFeedbackCountProvider), 0);
    });

    test('counts unread feedbacks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});
      container.listen(unreadFeedbackCountProvider, (_, __) {});

      ActionFeedbackService.show('a');
      ActionFeedbackService.show('b');

      expect(container.read(unreadFeedbackCountProvider), 2);
    });

    test('returns 0 after markAllRead', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});
      container.listen(unreadFeedbackCountProvider, (_, __) {});

      ActionFeedbackService.show('a');
      ActionFeedbackService.show('b');
      container.read(actionFeedbackProvider.notifier).markAllRead();

      expect(container.read(unreadFeedbackCountProvider), 0);
    });

    test('returns 0 after clearAll', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(actionFeedbackProvider, (_, __) {});
      container.listen(unreadFeedbackCountProvider, (_, __) {});

      ActionFeedbackService.show('a');
      container.read(actionFeedbackProvider.notifier).clearAll();

      expect(container.read(unreadFeedbackCountProvider), 0);
    });
  });
}
