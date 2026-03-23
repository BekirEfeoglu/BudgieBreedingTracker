import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart'
    show isFounderProvider;
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart'
    show isPremiumProvider;
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_dialog.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_header.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_item.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../../../helpers/test_localization.dart';

Profile _fakeProfile({
  String id = 'user-1',
  String email = 'test@example.com',
  String? fullName,
  String? role,
  bool isPremium = false,
}) => Profile(
  id: id,
  email: email,
  fullName: fullName,
  role: role,
  isPremium: isPremium,
);

void _consumeOverflowExceptions(WidgetTester tester) {
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Test',
      packageName: 'com.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileMenuDialog', () {
    testWidgets('renders without crashing', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileMenuDialog), findsOneWidget);
    });

    testWidgets('shows ProfileMenuHeader', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(fullName: 'Ali Veli'),
                  email: 'ali@test.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileMenuHeader), findsOneWidget);
    });

    testWidgets('shows multiple ProfileMenuItems', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      // Profile, Password, Settings, User Guide + Logout + Delete = at least 5
      expect(find.byType(ProfileMenuItem), findsAtLeastNWidgets(5));
    });

    testWidgets('shows profile.title menu item key', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.title'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows settings.title menu item key', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('settings.title'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows auth.logout menu item key', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('auth.logout'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows profile.delete_account key', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.delete_account'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows founder panel item when isFounder', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(true)),
                isPremiumProvider.overrideWithValue(true),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(role: 'founder'),
                  email: 'founder@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.founder_panel'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show founder panel when not founder', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(),
                  email: 'user@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.founder_panel'), findsNothing);
    });

    testWidgets('uses resolvedDisplayName from profile.fullName', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: ProfileMenuDialog(
                  profile: _fakeProfile(fullName: 'Tam İsim'),
                  email: 'test@example.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.text('Tam İsim'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses email prefix as displayName when fullName is null', (
      tester,
    ) async {
      // When profile.fullName is null, resolvedDisplayName falls back to profile.email prefix.
      // ProfileMenuDialog uses: profile?.resolvedDisplayName ?? email?.split('@').first
      // Since profile is not null, profile.resolvedDisplayName = profile.email.split('@').first = 'bekir'
      const profileWithEmailPrefix = Profile(
        id: 'user-1',
        email: 'bekir@test.com',
        fullName: null,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: const Scaffold(
                body: ProfileMenuDialog(
                  profile: profileWithEmailPrefix,
                  email: 'bekir@test.com',
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      // resolvedDisplayName falls back to email prefix ('bekir')
      expect(find.text('bekir'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with null profile gracefully', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: const Scaffold(
                body: ProfileMenuDialog(profile: null, email: null),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileMenuDialog), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      // Use a parent route so Navigator.pop() doesn't crash
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                authActionsProvider.overrideWith((_) => _FakeAuthActions()),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () {
                      showDialog<void>(
                        context: ctx,
                        builder: (_) => ProviderScope(
                          overrides: [
                            currentUserIdProvider.overrideWithValue('user-1'),
                            currentUserProvider.overrideWith((_) => null),
                            isFounderProvider.overrideWithValue(
                              const AsyncData(false),
                            ),
                            isPremiumProvider.overrideWithValue(false),
                            authActionsProvider.overrideWith(
                              (_) => _FakeAuthActions(),
                            ),
                            appInfoProvider.overrideWith((_) async {
                              throw UnimplementedError();
                            }),
                          ],
                          child: AlertDialog(
                            content: ProfileMenuDialog(
                              profile: _fakeProfile(),
                              email: 'test@example.com',
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      // Check that ProfileMenuItems and logout text are rendered
      // (via direct widget test without actually popping the router)
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            currentUserProvider.overrideWith((_) => null),
            isFounderProvider.overrideWithValue(const AsyncData(false)),
            isPremiumProvider.overrideWithValue(false),
            authActionsProvider.overrideWith((_) => _FakeAuthActions()),
            appInfoProvider.overrideWith((_) async {
              throw UnimplementedError();
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileMenuDialog(
                profile: _fakeProfile(),
                email: 'test@example.com',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      // Find the logout ProfileMenuItem
      final logoutMenuItems = tester.widgetList<ProfileMenuItem>(
        find.byType(ProfileMenuItem),
      );
      final logoutWidget = logoutMenuItems.firstWhere(
        (item) => item.label == 'auth.logout',
        orElse: () => logoutMenuItems.first,
      );

      // Invoke onTap directly to avoid GoRouter pop issues
      logoutWidget.onTap();
      await tester.pump(const Duration(milliseconds: 200));
      _consumeOverflowExceptions(tester);

      // Confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming logout signs out and navigates to login', (
      tester,
    ) async {
      var signOutCalls = 0;
      final authActions = _FakeAuthActions(onSignOut: () => signOutCalls++);

      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, __) => ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('user-1'),
                currentUserProvider.overrideWith((_) => null),
                isFounderProvider.overrideWithValue(const AsyncData(false)),
                isPremiumProvider.overrideWithValue(false),
                authActionsProvider.overrideWith((_) => authActions),
                appInfoProvider.overrideWith((_) async {
                  throw UnimplementedError();
                }),
              ],
              child: Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () {
                      showGeneralDialog(
                        context: ctx,
                        barrierDismissible: true,
                        barrierLabel: MaterialLocalizations.of(
                          ctx,
                        ).modalBarrierDismissLabel,
                        pageBuilder: (_, __, ___) => ProviderScope(
                          overrides: [
                            currentUserIdProvider.overrideWithValue('user-1'),
                            currentUserProvider.overrideWith((_) => null),
                            isFounderProvider.overrideWithValue(
                              const AsyncData(false),
                            ),
                            isPremiumProvider.overrideWithValue(false),
                            authActionsProvider.overrideWith(
                              (_) => authActions,
                            ),
                            appInfoProvider.overrideWith((_) async {
                              throw UnimplementedError();
                            }),
                          ],
                          child: ProfileMenuDialog(
                            profile: _fakeProfile(),
                            email: 'test@example.com',
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login_screen')),
          ),
        ],
      );

      await pumpLocalizedApp(tester,MaterialApp.router(routerConfig: router));
      _consumeOverflowExceptions(tester);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      _consumeOverflowExceptions(tester);

      await tester.tap(find.text('auth.logout').first);
      await tester.pumpAndSettle();
      _consumeOverflowExceptions(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'auth.logout'));
      await tester.pumpAndSettle();
      _consumeOverflowExceptions(tester);

      expect(signOutCalls, 1);
      expect(router.state.uri.path, '/login');
      expect(find.text('login_screen'), findsOneWidget);
    });

    testWidgets('ProfileAppVersionLabel shows nothing when appInfo fails', (
      tester,
    ) async {
      // Use plain MaterialApp (not GoRouter) to avoid animation ticker issues
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            currentUserProvider.overrideWith((_) => null),
            isFounderProvider.overrideWithValue(const AsyncData(false)),
            isPremiumProvider.overrideWithValue(false),
            appInfoProvider.overrideWith((_) async {
              throw UnimplementedError();
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileMenuDialog(
                profile: _fakeProfile(),
                email: 'test@example.com',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(); // allow FutureProvider to settle
      _consumeOverflowExceptions(tester);

      // When appInfo fails, SizedBox.shrink shown — no version text
      expect(find.textContaining('v1.'), findsNothing);
    });

    testWidgets('ProfileAppVersionLabel shows version when appInfo succeeds', (
      tester,
    ) async {
      // Use plain MaterialApp (not GoRouter) to avoid animation ticker issues
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            currentUserProvider.overrideWith((_) => null),
            isFounderProvider.overrideWithValue(const AsyncData(false)),
            isPremiumProvider.overrideWithValue(false),
            appInfoProvider.overrideWith((_) async {
              return PackageInfo(
                appName: 'Test',
                packageName: 'com.test',
                version: '2.3.4',
                buildNumber: '42',
                buildSignature: '',
              );
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileMenuDialog(
                profile: _fakeProfile(),
                email: 'test@example.com',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(); // FutureProvider settle
      _consumeOverflowExceptions(tester);

      expect(find.text('v2.3.4 (42)'), findsAtLeastNWidgets(1));
    });
  });
}

// -- Fake AuthActions --

class _FakeAuthActions implements AuthActions {
  _FakeAuthActions({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Future<void> signOut() async {
    onSignOut?.call();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
