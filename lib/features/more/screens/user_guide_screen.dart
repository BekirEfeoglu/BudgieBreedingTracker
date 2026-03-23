import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_list_item.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Map<String, String> _searchFoldMap = {
    'i̇': 'i',
    'ı': 'i',
    'ş': 's',
    'ç': 'c',
    'ğ': 'g',
    'ü': 'u',
    'ö': 'o',
    'ä': 'a',
    'â': 'a',
    'à': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'î': 'i',
    'í': 'i',
    'ì': 'i',
    'ô': 'o',
    'ó': 'o',
    'ò': 'o',
    'û': 'u',
    'ú': 'u',
    'ù': 'u',
    'ñ': 'n',
    'ß': 'ss',
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

  List<GuideTopic> get _filteredTopics {
    var topics = guideTopics.toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _normalizeSearchText(_searchQuery);
      topics = topics.where((t) {
        final titleMatch = _matchesQuery(t.title, query);
        if (titleMatch) return true;

        // Search through block text content
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

    return topics;
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;

    return Scaffold(
      appBar: AppBar(title: Text('user_guide.title'.tr())),
      body: Column(
        children: [
          // Search bar
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

          // Content
          Expanded(
            child: topics.isEmpty
                ? EmptyState(
                    icon: const AppIcon(AppIcons.search),
                    title: 'common.no_results'.tr(),
                    subtitle: 'common.no_results_hint'.tr(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xxxl * 2,
                    ),
                    itemCount: topics.length,
                    itemBuilder: (_, i) => GuideTopicListItem(
                      key: ValueKey(topics[i].titleKey),
                      topic: topics[i],
                      onTap: () {},
                      showDivider: i < topics.length - 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

