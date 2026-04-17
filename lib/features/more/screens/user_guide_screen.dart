import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_list_item.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Map<String, String> _searchFoldMap = {
    'i\u0307': 'i',
    '\u0131': 'i',
    '\u015f': 's',
    '\u00e7': 'c',
    '\u011f': 'g',
    '\u00fc': 'u',
    '\u00f6': 'o',
    '\u00e4': 'a',
    '\u00e2': 'a',
    '\u00e0': 'a',
    '\u00e1': 'a',
    '\u00e9': 'e',
    '\u00e8': 'e',
    '\u00ea': 'e',
    '\u00ee': 'i',
    '\u00ed': 'i',
    '\u00ec': 'i',
    '\u00f4': 'o',
    '\u00f3': 'o',
    '\u00f2': 'o',
    '\u00fb': 'u',
    '\u00fa': 'u',
    '\u00f9': 'u',
    '\u00f1': 'n',
    '\u00df': 'ss',
  };

  static String _normalizeSearchText(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';

    _searchFoldMap.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    return normalized;
  }

  static bool _matchesQuery(String candidate, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return _normalizeSearchText(candidate).contains(normalizedQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(int, GuideTopic)> get _filteredTopics {
    final indexed = <(int, GuideTopic)>[];
    for (var i = 0; i < guideTopics.length; i++) {
      indexed.add((i, guideTopics[i]));
    }

    if (_searchQuery.isEmpty) return indexed;

    final query = _normalizeSearchText(_searchQuery);
    return indexed.where((entry) {
      final t = entry.$2;
      if (_matchesQuery(t.title, query)) return true;
      for (final block in t.blocks) {
        if (block.textKey != null &&
            _matchesQuery(block.textKey!.tr(), query)) {
          return true;
        }
        if (block.stepsTitle != null &&
            _matchesQuery(block.stepsTitle!.tr(), query)) {
          return true;
        }
        if (block.stepKeys != null) {
          for (final key in block.stepKeys!) {
            if (_matchesQuery(key.tr(), query)) return true;
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'user_guide.title'.tr(),
          iconAsset: AppIcons.guide,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'user_guide.search_hint'.tr(),
                prefixIcon: const AppIcon(AppIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: topics.isEmpty
                ? EmptyState(
                    icon: const AppIcon(AppIcons.search),
                    title: 'common.no_results'.tr(),
                    subtitle: 'common.no_results_hint'.tr(),
                  )
                : isSearching
                ? _buildFlatList(topics)
                : _buildGroupedList(topics),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatList(List<(int, GuideTopic)> topics) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xxxl * 2,
      ),
      itemCount: topics.length,
      itemBuilder: (context, i) {
        final (index, topic) = topics[i];
        return GuideTopicListItem(
          topic: topic,
          showDivider: i < topics.length - 1,
          onTap: () => context.push('${AppRoutes.userGuide}/$index'),
        );
      },
    );
  }

  Widget _buildGroupedList(List<(int, GuideTopic)> topics) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (final category in GuideCategory.values) {
      final categoryTopics = topics
          .where((e) => e.$2.category == category)
          .toList();
      if (categoryTopics.isEmpty) continue;

      // Section header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg + AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            category.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // Grouped card
      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < categoryTopics.length; i++)
                GuideTopicListItem(
                  topic: categoryTopics[i].$2,
                  showDivider: i < categoryTopics.length - 1,
                  onTap: () =>
                      context.push('/user-guide/${categoryTopics[i].$1}'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xxxl * 2,
      ),
      children: widgets,
    );
  }
}
