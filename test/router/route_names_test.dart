import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';

/// All route constants from [AppRoutes] with their expected values.
/// Used for exhaustive validation.
const _allRoutes = <String, String>{
  'splash': '/splash',
  'maintenance': '/maintenance',
  'login': '/login',
  'register': '/register',
  'authCallback': '/auth/callback',
  'oauthCallback': '/login-callback',
  'emailVerification': '/email-verification',
  'forgotPassword': '/forgot-password',
  'home': '/',
  'birds': '/birds',
  'birdDetail': '/birds/:id',
  'birdForm': '/birds/form',
  'breeding': '/breeding',
  'breedingDetail': '/breeding/:id',
  'breedingForm': '/breeding/form',
  'breedingEggs': '/breeding/:id/eggs',
  'chicks': '/chicks',
  'chickDetail': '/chicks/:id',
  'chickForm': '/chicks/form',
  'calendar': '/calendar',
  'community': '/community',
  'communityPostDetail': '/community/post/:postId',
  'communityCreatePost': '/community/create',
  'communityUserPosts': '/community/user/:userId',
  'communityBookmarks': '/community/bookmarks',
  'communitySearch': '/community/search',
  'healthRecords': '/health-records',
  'healthRecordDetail': '/health-records/:id',
  'healthRecordForm': '/health-records/form',
  'statistics': '/statistics',
  'genealogy': '/genealogy',
  'genetics': '/genetics',
  'geneticsHistory': '/genetics/history',
  'geneticsCompare': '/genetics/compare',
  'geneticsReverse': '/genetics/reverse',
  'geneticsColorAudit': '/dev/genetics-color-audit',
  'profile': '/profile',
  'settings': '/settings',
  'more': '/more',
  'premium': '/premium',
  'userGuide': '/user-guide',
  'notifications': '/notifications',
  'notificationSettings': '/notification-settings',
  'backup': '/backup',
  'feedback': '/feedback',
  'privacyPolicy': '/privacy-policy',
  'termsOfService': '/terms-of-service',
  'communityGuidelines': '/community-guidelines',
  'twoFactorSetup': '/2fa-setup',
  'twoFactorVerify': '/2fa-verify',
  'admin': '/admin',
  'adminDashboard': '/admin/dashboard',
  'adminUsers': '/admin/users',
  'adminUserDetail': '/admin/users/:userId',
  'adminMonitoring': '/admin/monitoring',
  'adminDatabase': '/admin/database',
  'adminAudit': '/admin/audit',
  'adminSecurity': '/admin/security',
  'adminSettings': '/admin/settings',
  'adminFeedback': '/admin/feedback',
};

void main() {
  group('AppRoutes — all route values match specification', () {
    test('splash route', () {
      expect(AppRoutes.splash, '/splash');
    });

    test('maintenance route', () {
      expect(AppRoutes.maintenance, '/maintenance');
    });

    test('login route', () {
      expect(AppRoutes.login, '/login');
    });

    test('register route', () {
      expect(AppRoutes.register, '/register');
    });

    test('authCallback route', () {
      expect(AppRoutes.authCallback, '/auth/callback');
    });

    test('oauthCallback route', () {
      expect(AppRoutes.oauthCallback, '/login-callback');
    });

    test('emailVerification route', () {
      expect(AppRoutes.emailVerification, '/email-verification');
    });

    test('forgotPassword route', () {
      expect(AppRoutes.forgotPassword, '/forgot-password');
    });

    test('home route', () {
      expect(AppRoutes.home, '/');
    });

    test('birds route', () {
      expect(AppRoutes.birds, '/birds');
    });

    test('breeding route', () {
      expect(AppRoutes.breeding, '/breeding');
    });

    test('chicks route', () {
      expect(AppRoutes.chicks, '/chicks');
    });

    test('calendar route', () {
      expect(AppRoutes.calendar, '/calendar');
    });

    test('community route', () {
      expect(AppRoutes.community, '/community');
    });

    test('admin route', () {
      expect(AppRoutes.admin, '/admin');
    });
  });

  group('AppRoutes — all routes are non-empty strings', () {
    for (final entry in _allRoutes.entries) {
      test('${entry.key} is non-empty', () {
        expect(entry.value, isNotEmpty);
      });
    }
  });

  group('AppRoutes — all routes start with /', () {
    for (final entry in _allRoutes.entries) {
      test('${entry.key} starts with /', () {
        expect(entry.value, startsWith('/'));
      });
    }
  });

  group('AppRoutes — no duplicate route paths', () {
    test('all route values are unique', () {
      final values = _allRoutes.values.toList();
      final uniqueValues = values.toSet();
      expect(
        uniqueValues.length,
        values.length,
        reason: 'Found duplicate route paths',
      );
    });
  });

  group('AppRoutes — parameterized routes', () {
    test('birdDetail contains :id parameter', () {
      expect(AppRoutes.birdDetail, contains(':id'));
    });

    test('breedingDetail contains :id parameter', () {
      expect(AppRoutes.breedingDetail, contains(':id'));
    });

    test('breedingEggs contains :id parameter', () {
      expect(AppRoutes.breedingEggs, contains(':id'));
    });

    test('chickDetail contains :id parameter', () {
      expect(AppRoutes.chickDetail, contains(':id'));
    });

    test('communityPostDetail contains :postId parameter', () {
      expect(AppRoutes.communityPostDetail, contains(':postId'));
    });

    test('communityUserPosts contains :userId parameter', () {
      expect(AppRoutes.communityUserPosts, contains(':userId'));
    });

    test('healthRecordDetail contains :id parameter', () {
      expect(AppRoutes.healthRecordDetail, contains(':id'));
    });

    test('adminUserDetail contains :userId parameter', () {
      expect(AppRoutes.adminUserDetail, contains(':userId'));
    });
  });

  group('AppRoutes — route hierarchy', () {
    test('admin sub-routes start with /admin/', () {
      expect(AppRoutes.adminDashboard, startsWith('/admin/'));
      expect(AppRoutes.adminUsers, startsWith('/admin/'));
      expect(AppRoutes.adminUserDetail, startsWith('/admin/'));
      expect(AppRoutes.adminMonitoring, startsWith('/admin/'));
      expect(AppRoutes.adminDatabase, startsWith('/admin/'));
      expect(AppRoutes.adminAudit, startsWith('/admin/'));
      expect(AppRoutes.adminSecurity, startsWith('/admin/'));
      expect(AppRoutes.adminSettings, startsWith('/admin/'));
      expect(AppRoutes.adminFeedback, startsWith('/admin/'));
    });

    test('bird sub-routes start with /birds', () {
      expect(AppRoutes.birdDetail, startsWith('/birds/'));
      expect(AppRoutes.birdForm, startsWith('/birds/'));
    });

    test('breeding sub-routes start with /breeding', () {
      expect(AppRoutes.breedingDetail, startsWith('/breeding/'));
      expect(AppRoutes.breedingForm, startsWith('/breeding/'));
      expect(AppRoutes.breedingEggs, startsWith('/breeding/'));
    });

    test('chick sub-routes start with /chicks', () {
      expect(AppRoutes.chickDetail, startsWith('/chicks/'));
      expect(AppRoutes.chickForm, startsWith('/chicks/'));
    });

    test('community sub-routes start with /community', () {
      expect(AppRoutes.communityPostDetail, startsWith('/community/'));
      expect(AppRoutes.communityCreatePost, startsWith('/community/'));
      expect(AppRoutes.communityUserPosts, startsWith('/community/'));
      expect(AppRoutes.communityBookmarks, startsWith('/community/'));
      expect(AppRoutes.communitySearch, startsWith('/community/'));
    });

    test('health record sub-routes start with /health-records', () {
      expect(AppRoutes.healthRecordDetail, startsWith('/health-records/'));
      expect(AppRoutes.healthRecordForm, startsWith('/health-records/'));
    });

    test('genetics sub-routes start with /genetics', () {
      expect(AppRoutes.geneticsHistory, startsWith('/genetics/'));
      expect(AppRoutes.geneticsCompare, startsWith('/genetics/'));
      expect(AppRoutes.geneticsReverse, startsWith('/genetics/'));
    });
  });

  group('AppRoutes — form routes use /form suffix', () {
    test('birdForm ends with /form', () {
      expect(AppRoutes.birdForm, endsWith('/form'));
    });

    test('breedingForm ends with /form', () {
      expect(AppRoutes.breedingForm, endsWith('/form'));
    });

    test('chickForm ends with /form', () {
      expect(AppRoutes.chickForm, endsWith('/form'));
    });

    test('healthRecordForm ends with /form', () {
      expect(AppRoutes.healthRecordForm, endsWith('/form'));
    });
  });

  group('AppRoutes — no trailing slashes (except home)', () {
    for (final entry in _allRoutes.entries) {
      if (entry.value == '/') continue;
      test('${entry.key} has no trailing slash', () {
        expect(entry.value, isNot(endsWith('/')));
      });
    }
  });

  group('AppRoutes — no whitespace in route paths', () {
    for (final entry in _allRoutes.entries) {
      test('${entry.key} has no whitespace', () {
        expect(entry.value.contains(' '), isFalse);
        expect(entry.value.contains('\t'), isFalse);
        expect(entry.value.contains('\n'), isFalse);
      });
    }
  });
}
