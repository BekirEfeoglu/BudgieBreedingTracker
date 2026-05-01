import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

class NewDmScreen extends ConsumerStatefulWidget {
  const NewDmScreen({super.key});

  @override
  ConsumerState<NewDmScreen> createState() => _NewDmScreenState();
}

class _NewDmScreenState extends ConsumerState<NewDmScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _startingDmWith;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(messagingRepositoryProvider);
      final results = await repo.searchProfiles(query, excludeUserId: userId);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e, st) {
      AppLogger.error('NewDmScreen', e, st);
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startConversation(String targetUserId) async {
    setState(() => _startingDmWith = targetUserId);
    final userId = ref.read(currentUserIdProvider);
    final conversationId = await ref
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(userId1: userId, userId2: targetUserId);

    if (!mounted) return;
    setState(() => _startingDmWith = null);

    if (conversationId != null) {
      ref.read(messagingFormStateProvider.notifier).reset();
      context.pushReplacement('${AppRoutes.messages}/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('messaging.direct_message'.tr())),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screenPadding,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'messaging.search_user_hint'.tr(),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? AppIconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        semanticLabel: 'common.clear'.tr(),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: LoadingState(),
            )
          else if (_results.isEmpty &&
              _searchController.text.trim().length >= 2)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'common.no_results'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xxxl,
                ),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return _UserTile(
                    user: user,
                    isLoading: _startingDmWith == user['id'],
                    onTap: () => _startConversation(user['id'] as String),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isLoading;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        (user['display_name'] as String?) ??
        (user['full_name'] as String?) ??
        'messaging.unknown_user'.tr();
    final avatarUrl = user['avatar_url'] as String?;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: avatarUrl != null
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl == null
            ? Text(
                initial,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(displayName, overflow: TextOverflow.ellipsis),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              LucideIcons.messageCircle,
              size: 18,
              color: theme.colorScheme.primary,
            ),
      onTap: isLoading ? null : onTap,
    );
  }
}
