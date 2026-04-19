import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';

/// Direct-list entity selector for genealogy tree.
/// Shows a search field and a scrollable list of all birds and chicks.
class EntitySelector extends StatefulWidget {
  final List<Bird> birds;
  final List<Chick> chicks;
  final GenealogySelection? selection;
  final ValueChanged<GenealogySelection?> onChanged;

  const EntitySelector({
    super.key,
    required this.birds,
    required this.chicks,
    required this.selection,
    required this.onChanged,
  });

  @override
  State<EntitySelector> createState() => _EntitySelectorState();
}

class _EntitySelectorState extends State<EntitySelector> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ({List<_EntityOption> birds, List<_EntityOption> chicks})
  _buildFilteredOptions() {
    final birdOptions = <_EntityOption>[];
    final chickOptions = <_EntityOption>[];

    for (final bird in widget.birds) {
      birdOptions.add((
        selection: (id: bird.id, isChick: false),
        displayName: bird.name,
        ringNumber: bird.ringNumber,
        isChick: false,
      ));
    }

    for (final chick in widget.chicks) {
      final name =
          chick.name ??
          'chicks.unnamed_chick'.tr(
            args: [chick.ringNumber ?? chick.id.substring(0, 6)],
          );
      chickOptions.add((
        selection: (id: chick.id, isChick: true),
        displayName: name,
        ringNumber: chick.ringNumber,
        isChick: true,
      ));
    }

    if (_query.isEmpty) return (birds: birdOptions, chicks: chickOptions);

    final q = _query.toLowerCase();
    bool matches(_EntityOption o) =>
        o.displayName.toLowerCase().contains(q) ||
        (o.ringNumber?.toLowerCase().contains(q) ?? false);
    return (
      birds: birdOptions.where(matches).toList(),
      chicks: chickOptions.where(matches).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (:birds, :chicks) = _buildFilteredOptions();
    final isEmpty = birds.isEmpty && chicks.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'genealogy.search_bird'.tr(),
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              isDense: true,
              suffixIcon: _query.isNotEmpty
                  ? AppIconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      semanticLabel: 'common.clear'.tr(),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: isEmpty
              ? Center(
                  child: Text(
                    'common.no_results'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    if (birds.isNotEmpty) ...[
                      _StickyHeader(
                        icon: AppIcon(
                          AppIcons.bird,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        title: 'birds.title'.tr(),
                        count: birds.length,
                      ),
                      SliverList.builder(
                        itemCount: birds.length,
                        itemBuilder: (_, i) => _buildTile(theme, birds[i]),
                      ),
                    ],
                    if (chicks.isNotEmpty) ...[
                      _StickyHeader(
                        icon: AppIcon(
                          AppIcons.egg,
                          size: 18,
                          color: theme.colorScheme.tertiary,
                        ),
                        title: 'chicks.title'.tr(),
                        count: chicks.length,
                      ),
                      SliverList.builder(
                        itemCount: chicks.length,
                        itemBuilder: (_, i) => _buildTile(theme, chicks[i]),
                      ),
                    ],
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTile(ThemeData theme, _EntityOption option) {
    final isSelected = widget.selection == option.selection;
    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ),
      leading: option.isChick
          ? AppIcon(AppIcons.egg, size: 18, color: theme.colorScheme.tertiary)
          : AppIcon(AppIcons.bird, size: 18, color: theme.colorScheme.primary),
      title: Text(
        option.displayName,
        overflow: TextOverflow.ellipsis,
        style: isSelected
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              )
            : null,
      ),
      subtitle: option.ringNumber != null
          ? Text(option.ringNumber!, style: theme.textTheme.bodySmall)
          : null,
      trailing: isSelected
          ? Icon(
              LucideIcons.check,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            )
          : null,
      dense: true,
      onTap: () => widget.onChanged(option.selection),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  final int count;

  const _StickyHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        icon: icon,
        title: title,
        count: count,
        theme: Theme.of(context),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget icon;
  final String title;
  final int count;
  final ThemeData theme;

  const _StickyHeaderDelegate({
    required this.icon,
    required this.title,
    required this.count,
    required this.theme,
  });

  @override
  double get minExtent => _StickyHeader._height;
  @override
  double get maxExtent => _StickyHeader._height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Semantics(
      header: true,
      child: Container(
        height: _StickyHeader._height,
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '($count)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      title != oldDelegate.title || count != oldDelegate.count;
}

typedef _EntityOption = ({
  GenealogySelection selection,
  String displayName,
  String? ringNumber,
  bool isChick,
});
