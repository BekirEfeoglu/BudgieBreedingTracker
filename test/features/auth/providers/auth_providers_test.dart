import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// -- Mocks --

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  group('currentUserIdProvider', () {
    test('returns user ID when authenticated', () {
      final mockUser = MockUser();
      when(
        () => mockUser.id,
      ).thenReturn('141aa2f1-2db4-4fb0-a381-b4e14e65063b');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(const AuthState(AuthChangeEvent.signedIn, null)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      final userId = container.read(currentUserIdProvider);
      expect(userId, '141aa2f1-2db4-4fb0-a381-b4e14e65063b');
    });

    test('returns "anonymous" when not authenticated', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(const AuthState(AuthChangeEvent.signedOut, null)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      final userId = container.read(currentUserIdProvider);
      expect(userId, 'anonymous');
    });

    test('updates reactively on sign-in', () async {
      final authStreamController = StreamController<AuthState>.broadcast();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(
        () => mockAuth.onAuthStateChange,
      ).thenAnswer((_) => authStreamController.stream);

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(() {
        container.dispose();
        authStreamController.close();
      });

      // Activate provider so it rebuilds reactively when stream emits
      container.listen(currentUserIdProvider, (_, __) {});

      // Initially anonymous
      expect(container.read(currentUserIdProvider), 'anonymous');

      // Simulate sign-in
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-uuid-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      authStreamController.add(const AuthState(AuthChangeEvent.signedIn, null));

      // Allow async listeners to fire
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserIdProvider), 'user-uuid-123');
    });

    test('updates reactively on sign-out', () async {
      final authStreamController = StreamController<AuthState>.broadcast();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-uuid-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockAuth.onAuthStateChange,
      ).thenAnswer((_) => authStreamController.stream);

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(() {
        container.dispose();
        authStreamController.close();
      });

      // Activate provider so it rebuilds reactively when stream emits
      container.listen(currentUserIdProvider, (_, __) {});

      // Initially authenticated
      expect(container.read(currentUserIdProvider), 'user-uuid-123');

      // Simulate sign-out
      when(() => mockAuth.currentUser).thenReturn(null);
      authStreamController.add(
        const AuthState(AuthChangeEvent.signedOut, null),
      );

      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserIdProvider), 'anonymous');
    });
  });

  group('isAuthenticatedProvider', () {
    test('returns true when session exists', () {
      final mockSession = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: MockUser(),
      );
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(AuthState(AuthChangeEvent.signedIn, mockSession)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('returns false when no session', () {
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(const AuthState(AuthChangeEvent.signedOut, null)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('returns false when Supabase not initialized', () {
      final container = ProviderContainer(
        overrides: [supabaseInitializedProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });

  group('authStateProvider', () {
    test('stays unresolved when Supabase is not initialized', () {
      final container = ProviderContainer(
        overrides: [supabaseInitializedProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      final state = container.read(authStateProvider);
      expect(state.hasValue, isFalse);
      expect(state.isLoading, isTrue);
    });

    test('delegates auth state changes stream from Supabase client', () async {
      final session = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: MockUser(),
      );
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(AuthState(AuthChangeEvent.signedIn, session)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      container.listen(authStateProvider, (_, __) {});
      final state = await container.read(authStateProvider.future);
      expect(state.event, AuthChangeEvent.signedIn);
    });
  });

  group('currentUserProvider', () {
    test('returns current user from Supabase auth client', () {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream.value(const AuthState(AuthChangeEvent.signedIn, null)),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentUserProvider), same(user));
    });
  });

  group('mapAuthError', () {
    test('maps invalid credentials', () {
      const error = AuthException('Invalid login credentials');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });

    test('maps email not confirmed', () {
      const error = AuthException('Email not confirmed');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });

    test('maps rate limit', () {
      const error = AuthException('Too many requests');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });

    test('maps user already registered', () {
      const error = AuthException('User already registered');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });

    test('maps weak password', () {
      const error = AuthException('Password should be at least 8 characters');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });

    test('maps unknown error', () {
      const error = AuthException('Something went wrong');
      final result = mapAuthError(error);
      expect(result, isNotEmpty);
    });
  });
}
