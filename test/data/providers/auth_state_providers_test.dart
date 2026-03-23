import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  group('supabaseInitializedProvider', () {
    test('returns false when Supabase is not initialized', () {
      // By default in tests, Supabase singleton is not initialized.
      // Override supabaseClientProvider so it does not try the real singleton.
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      // supabaseInitializedProvider checks Supabase.instance.client,
      // which is not initialized in test environment. It should return false.
      final result = container.read(supabaseInitializedProvider);
      expect(result, isFalse);
    });
  });

  group('isAuthenticatedProvider', () {
    test('returns false when Supabase is not initialized', () {
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(isAuthenticatedProvider);
      expect(result, isFalse);
    });

    test('returns true when session exists', () {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final mockSession = MockSession();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
          authStateProvider.overrideWith(
            (ref) => const Stream<AuthState>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(isAuthenticatedProvider);
      expect(result, isTrue);
    });

    test('returns false when session is null', () {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
          authStateProvider.overrideWith(
            (ref) => const Stream<AuthState>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(isAuthenticatedProvider);
      expect(result, isFalse);
    });
  });

  group('currentUserIdProvider', () {
    test('returns anonymous when Supabase is not initialized', () {
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(currentUserIdProvider);
      expect(result, 'anonymous');
    });

    test('returns user ID when authenticated', () {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final mockUser = MockUser();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-abc-123');
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
          authStateProvider.overrideWith(
            (ref) => const Stream<AuthState>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(currentUserIdProvider);
      expect(result, 'user-abc-123');
    });

    test('returns anonymous when currentUser is null', () {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
          authStateProvider.overrideWith(
            (ref) => const Stream<AuthState>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(currentUserIdProvider);
      expect(result, 'anonymous');
    });
  });

  group('authStateProvider', () {
    test('emits empty stream when Supabase is not initialized', () async {
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(authStateProvider);
      // When not initialized, the stream is empty so it stays loading
      expect(asyncValue, isA<AsyncLoading>());
    });

    test('provides auth state stream when initialized', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final controller = StreamController<AuthState>.broadcast();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.onAuthStateChange)
          .thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      // Initially loading
      final initial = container.read(authStateProvider);
      expect(initial, isA<AsyncLoading>());
    });
  });
}
