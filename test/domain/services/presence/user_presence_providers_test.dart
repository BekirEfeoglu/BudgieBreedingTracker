import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakePresenceService extends UserPresenceService {
  _FakePresenceService() : super(_FakeSupabaseClient());

  final startedUsers = <String>[];
  final endedSessions = <String>[];

  @override
  Future<String?> startSession(String userId) async {
    startedUsers.add(userId);
    return 'session-$userId';
  }

  @override
  Future<void> heartbeat({
    required String userId,
    required String sessionId,
  }) async {}

  @override
  Future<void> endSession({
    required String userId,
    required String sessionId,
  }) async {
    endedSessions.add(sessionId);
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  testWidgets(
    'userPresenceLifecycleProvider defers state changes after build',
    (tester) async {
      final service = _FakePresenceService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            userPresenceServiceProvider.overrideWithValue(service),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(userPresenceLifecycleProvider);
              ref.watch(userPresenceControllerProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(service.startedUsers, ['user-1']);
    },
  );
}
