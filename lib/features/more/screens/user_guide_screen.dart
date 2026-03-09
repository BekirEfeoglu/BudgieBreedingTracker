import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_card.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _searchController = TextEditingController();
  GuideCategory _selectedCategory = GuideCategory.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GuideTopic> get _filteredTopics {
    var topics = guideTopics.toList();

    // Category filter
    if (_selectedCategory != GuideCategory.all) {
      topics = topics
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      topics = topics.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        if (titleMatch) return true;

        // Search through block text content
        for (final block in t.blocks) {
          if (block.textKey != null &&
              block.textKey!.tr().toLowerCase().contains(query)) {
            return true;
          }
          if (block.stepsTitle != null &&
              block.stepsTitle!.tr().toLowerCase().contains(query)) {
            return true;
          }
          if (block.stepKeys != null) {
            for (final key in block.stepKeys!) {
              if (key.tr().toLowerCase().contains(query)) return true;
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
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category chips
          _CategoryChipBar(
            selected: _selectedCategory,
            onSelected: (cat) =>
                setState(() => _selectedCategory = cat),
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
                    itemBuilder: (_, i) =>
                        GuideTopicCard(topic: topics[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal scrollable category chip bar
// ---------------------------------------------------------------------------

class _CategoryChipBar extends StatelessWidget {
  final GuideCategory selected;
  final ValueChanged<GuideCategory> onSelected;

  const _CategoryChipBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const categories = GuideCategory.values;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;

          return ChoiceChip(
            label: Text(cat.label),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
          );
        },
      ),
    );
  }
}
