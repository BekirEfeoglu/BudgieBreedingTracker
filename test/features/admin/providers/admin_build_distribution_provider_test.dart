import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_build_distribution_provider.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

class _FakeMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingleBuilder(this.result);

  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestMap?>.value(result).then(onValue, onError: onError);
  }
}

class _FakeAdminFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeAdminFilterBuilder(this.adminRow);

  final PostgrestMap? adminRow;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return _FakeMaybeSingleBuilder(adminRow);
  }
}

class _FakeAdminQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeAdminQueryBuilder(this.adminRow);

  final PostgrestMap? adminRow;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeAdminFilterBuilder(adminRow);
  }
}

class _FakeRpcBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpcBuilder(this.result);

  final T result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(result).then(onValue, onError: onError);
  }
}

class _FakeClient extends Fake implements SupabaseClient {
  _FakeClient({required this.adminRow, required this.rpcResult});

  final PostgrestMap? adminRow;
  final Object rpcResult;
  String? rpcName;
  Map<String, dynamic>? rpcParams;

  @override
  SupabaseQueryBuilder from(String table) {
    expect(table, SupabaseConstants.profilesTable);
    return _FakeAdminQueryBuilder(adminRow);
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcName = fn;
    rpcParams = params;
    return _FakeRpcBuilder<T>(rpcResult as T);
  }
}

const _payload = <String, dynamic>{
  'window_days': 30,
  'generated_at': '2026-07-29T18:00:00Z',
  'platforms': [
    {
      'platform': 'ios',
      'total_users': 6,
      'versioned_users': 5,
      'coverage_percent': 83.3,
      'builds': [
        {
          'app_version': '1.1.9+61',
          'user_count': 4,
          'adoption_percent': 66.7,
          'last_seen_at': '2026-07-29T17:30:00Z',
        },
      ],
    },
  ],
};

ProviderContainer _container(_FakeClient client) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('admin-user'),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

void main() {
  group('BuildDistribution parsing', () {
    test('parses platform coverage and build adoption', () {
      final distribution = BuildDistribution.fromJson(_payload);

      expect(distribution.windowDays, 30);
      expect(distribution.generatedAt, DateTime.utc(2026, 7, 29, 18));
      expect(distribution.platforms.single.platform, 'ios');
      expect(distribution.platforms.single.totalUsers, 6);
      expect(distribution.platforms.single.versionedUsers, 5);
      expect(
        distribution.platforms.single.builds.single.appVersion,
        '1.1.9+61',
      );
      expect(distribution.platforms.single.builds.single.userCount, 4);
    });

    test('rejects impossible coverage values', () {
      final invalid = Map<String, dynamic>.from(_payload);
      invalid['platforms'] = [
        {
          'platform': 'ios',
          'total_users': 2,
          'versioned_users': 3,
          'coverage_percent': 150,
          'builds': const [],
        },
      ];

      expect(
        () => BuildDistribution.fromJson(invalid),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('adminBuildDistributionProvider', () {
    test('requires admin and requests the configured 30-day window', () async {
      final client = _FakeClient(
        adminRow: {'role': 'admin', 'is_active': true},
        rpcResult: _payload,
      );
      final container = _container(client);
      addTearDown(container.dispose);

      final distribution = await container.read(
        adminBuildDistributionProvider.future,
      );

      expect(distribution.platforms.single.platform, 'ios');
      expect(client.rpcName, SupabaseConstants.adminGetBuildDistributionRpc);
      expect(client.rpcParams, {'p_days': 30});
    });

    test('does not call the RPC for a non-admin user', () async {
      final client = _FakeClient(
        adminRow: {'role': 'member', 'is_active': true},
        rpcResult: _payload,
      );
      final container = _container(client);
      addTearDown(container.dispose);

      await expectLater(
        container.read(adminBuildDistributionProvider.future),
        throwsA(isA<Exception>()),
      );

      expect(client.rpcName, isNull);
    });
  });
}
