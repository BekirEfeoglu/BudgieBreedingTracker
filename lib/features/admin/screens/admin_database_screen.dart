import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_database_widgets.dart';

/// Database overview screen showing table list with row counts,
/// backup and reset options.
class AdminDatabaseScreen extends ConsumerWidget {
  const AdminDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(adminDatabaseInfoProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDatabaseInfoProvider),
        child: dbAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(adminDatabaseInfoProvider),
          ),
          data: (tables) => DatabaseContent(tables: tables),
        ),
      ),
    );
  }
}
