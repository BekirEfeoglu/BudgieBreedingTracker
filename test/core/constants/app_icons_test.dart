import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';

/// All icon constants from [AppIcons] for exhaustive testing.
const _allIcons = <String, String>{
  // Navigation
  'home': AppIcons.home,
  'bird': AppIcons.bird,
  'breeding': AppIcons.breeding,
  'calendar': AppIcons.calendar,
  'statistics': AppIcons.statistics,
  'community': AppIcons.community,
  'more': AppIcons.more,
  // Birds
  'male': AppIcons.male,
  'female': AppIcons.female,
  'ring': AppIcons.ring,
  'health': AppIcons.health,
  'statusAlive': AppIcons.statusAlive,
  'statusSold': AppIcons.statusSold,
  'budgie': AppIcons.budgie,
  'canary': AppIcons.canary,
  'finch': AppIcons.finch,
  'birdOther': AppIcons.birdOther,
  'statusDead': AppIcons.statusDead,
  'photo': AppIcons.photo,
  'budgieNestAnimated': AppIcons.budgieNestAnimated,
  'species': AppIcons.species,
  // Breeding
  'pair': AppIcons.pair,
  'nest': AppIcons.nest,
  'incubation': AppIcons.incubation,
  'breedingActive': AppIcons.breedingActive,
  'breedingComplete': AppIcons.breedingComplete,
  // Eggs
  'egg': AppIcons.egg,
  'fertile': AppIcons.fertile,
  'hatched': AppIcons.hatched,
  'infertile': AppIcons.infertile,
  'damaged': AppIcons.damaged,
  'incubating': AppIcons.incubating,
  // Chicks
  'chick': AppIcons.chick,
  'growth': AppIcons.growth,
  'promote': AppIcons.promote,
  'care': AppIcons.care,
  // Genetics
  'dna': AppIcons.dna,
  'punnett': AppIcons.punnett,
  'mutation': AppIcons.mutation,
  'colorPalette': AppIcons.colorPalette,
  'genealogy': AppIcons.genealogy,
  'calculator': AppIcons.calculator,
  // Admin
  'dashboard': AppIcons.dashboard,
  'users': AppIcons.users,
  'security': AppIcons.security,
  'database': AppIcons.database,
  'monitoring': AppIcons.monitoring,
  'audit': AppIcons.audit,
  // Community
  'like': AppIcons.like,
  'comment': AppIcons.comment,
  'share': AppIcons.share,
  'leaderboard': AppIcons.leaderboard,
  'poll': AppIcons.poll,
  'post': AppIcons.post,
  'story': AppIcons.story,
  'bookmark': AppIcons.bookmark,
  // Settings
  'settings': AppIcons.settings,
  'profile': AppIcons.profile,
  'language': AppIcons.language,
  'notification': AppIcons.notification,
  'premium': AppIcons.premium,
  'theme': AppIcons.theme,
  'password': AppIcons.password,
  // General
  'sync': AppIcons.sync,
  'offline': AppIcons.offline,
  'backup': AppIcons.backup,
  'export': AppIcons.export,
  'search': AppIcons.search,
  'filter': AppIcons.filter,
  'add': AppIcons.add,
  'delete': AppIcons.delete,
  'edit': AppIcons.edit,
  'info': AppIcons.info,
  'warning': AppIcons.warning,
  'pdf': AppIcons.pdf,
  'excel': AppIcons.excel,
  'weight': AppIcons.weight,
  'onboarding': AppIcons.onboarding,
  'guide': AppIcons.guide,
  'haptic': AppIcons.haptic,
  'twoFactor': AppIcons.twoFactor,
  'conflict': AppIcons.conflict,
};

/// Expected subdirectories under assets/icons/.
const _expectedSubdirectories = [
  'navigation',
  'birds',
  'breeding',
  'eggs',
  'chicks',
  'genetics',
  'admin',
  'community',
  'settings',
  'general',
];

void main() {
  group('AppIcons — all icon paths are non-empty', () {
    for (final entry in _allIcons.entries) {
      test('${entry.key} is non-empty', () {
        expect(entry.value, isNotEmpty);
      });
    }
  });

  group('AppIcons — all icon paths start with assets/icons/', () {
    for (final entry in _allIcons.entries) {
      test('${entry.key} starts with assets/icons/', () {
        expect(entry.value, startsWith('assets/icons/'));
      });
    }
  });

  group('AppIcons — all icon paths end with .svg', () {
    for (final entry in _allIcons.entries) {
      test('${entry.key} ends with .svg', () {
        expect(entry.value, endsWith('.svg'));
      });
    }
  });

  group('AppIcons — icon paths use correct subdirectory', () {
    test('navigation icons use navigation/ subdirectory', () {
      expect(AppIcons.home, contains('/navigation/'));
      expect(AppIcons.bird, contains('/navigation/'));
      expect(AppIcons.breeding, contains('/navigation/'));
      expect(AppIcons.calendar, contains('/navigation/'));
      expect(AppIcons.statistics, contains('/navigation/'));
      expect(AppIcons.community, contains('/navigation/'));
      expect(AppIcons.more, contains('/navigation/'));
    });

    test('bird icons use birds/ subdirectory', () {
      expect(AppIcons.male, contains('/birds/'));
      expect(AppIcons.female, contains('/birds/'));
      expect(AppIcons.ring, contains('/birds/'));
      expect(AppIcons.health, contains('/birds/'));
      expect(AppIcons.statusAlive, contains('/birds/'));
      expect(AppIcons.budgie, contains('/birds/'));
    });

    test('breeding icons use breeding/ subdirectory', () {
      expect(AppIcons.pair, contains('/breeding/'));
      expect(AppIcons.nest, contains('/breeding/'));
      expect(AppIcons.incubation, contains('/breeding/'));
    });

    test('egg icons use eggs/ subdirectory', () {
      expect(AppIcons.egg, contains('/eggs/'));
      expect(AppIcons.fertile, contains('/eggs/'));
      expect(AppIcons.hatched, contains('/eggs/'));
      expect(AppIcons.infertile, contains('/eggs/'));
      expect(AppIcons.damaged, contains('/eggs/'));
      expect(AppIcons.incubating, contains('/eggs/'));
    });

    test('chick icons use chicks/ subdirectory', () {
      expect(AppIcons.chick, contains('/chicks/'));
      expect(AppIcons.growth, contains('/chicks/'));
      expect(AppIcons.promote, contains('/chicks/'));
      expect(AppIcons.care, contains('/chicks/'));
    });

    test('genetics icons use genetics/ subdirectory', () {
      expect(AppIcons.dna, contains('/genetics/'));
      expect(AppIcons.punnett, contains('/genetics/'));
      expect(AppIcons.mutation, contains('/genetics/'));
      expect(AppIcons.genealogy, contains('/genetics/'));
      expect(AppIcons.calculator, contains('/genetics/'));
    });

    test('admin icons use admin/ subdirectory', () {
      expect(AppIcons.dashboard, contains('/admin/'));
      expect(AppIcons.users, contains('/admin/'));
      expect(AppIcons.security, contains('/admin/'));
      expect(AppIcons.database, contains('/admin/'));
      expect(AppIcons.monitoring, contains('/admin/'));
      expect(AppIcons.audit, contains('/admin/'));
    });

    test('community icons use community/ subdirectory', () {
      expect(AppIcons.like, contains('/community/'));
      expect(AppIcons.comment, contains('/community/'));
      expect(AppIcons.share, contains('/community/'));
      expect(AppIcons.leaderboard, contains('/community/'));
      expect(AppIcons.bookmark, contains('/community/'));
    });

    test('settings icons use settings/ subdirectory', () {
      expect(AppIcons.settings, contains('/settings/'));
      expect(AppIcons.profile, contains('/settings/'));
      expect(AppIcons.language, contains('/settings/'));
      expect(AppIcons.notification, contains('/settings/'));
      expect(AppIcons.premium, contains('/settings/'));
      expect(AppIcons.theme, contains('/settings/'));
      expect(AppIcons.password, contains('/settings/'));
    });

    test('general icons use general/ subdirectory', () {
      expect(AppIcons.sync, contains('/general/'));
      expect(AppIcons.offline, contains('/general/'));
      expect(AppIcons.backup, contains('/general/'));
      expect(AppIcons.search, contains('/general/'));
      expect(AppIcons.filter, contains('/general/'));
      expect(AppIcons.add, contains('/general/'));
      expect(AppIcons.delete, contains('/general/'));
      expect(AppIcons.edit, contains('/general/'));
    });
  });

  group('AppIcons — all subdirectories are covered', () {
    test('all 10 expected subdirectories appear in icon paths', () {
      final usedDirs = <String>{};
      for (final path in _allIcons.values) {
        // Extract subdirectory: assets/icons/<subdir>/file.svg
        final segments = path.split('/');
        if (segments.length >= 3) {
          usedDirs.add(segments[2]);
        }
      }
      for (final dir in _expectedSubdirectories) {
        expect(
          usedDirs,
          contains(dir),
          reason: 'Subdirectory "$dir" should be used by at least one icon',
        );
      }
    });
  });

  group('AppIcons — no duplicate paths', () {
    test('all icon paths are unique', () {
      final values = _allIcons.values.toList();
      final uniqueValues = values.toSet();
      expect(
        uniqueValues.length,
        values.length,
        reason: 'All icon paths should be unique',
      );
    });
  });

  group('AppIcons — icon count', () {
    test('has at least 82 icon constants', () {
      expect(_allIcons.length, greaterThanOrEqualTo(82));
    });
  });

  group('AppIcons — path format validation', () {
    for (final entry in _allIcons.entries) {
      test('${entry.key} has valid path format (no spaces, no special chars)', () {
        // SVG paths should only contain alphanumeric, underscore, forward slash, dot, hyphen
        expect(
          RegExp(r'^[a-zA-Z0-9/_.\-]+$').hasMatch(entry.value),
          isTrue,
          reason: 'Path "${entry.value}" contains invalid characters',
        );
      });
    }
  });
}
