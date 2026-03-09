import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Search bar for filtering birds by name or ring number.
class BirdSearchBar extends ConsumerStatefulWidget {
  const BirdSearchBar({super.key});

  @override
  ConsumerState<BirdSearchBar> createState() => _BirdSearchBarState();
}

class _BirdSearchBarState extends ConsumerState<BirdSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(birdSearchQueryProvider);

    // Sync controller when query is cleared externally
    if (query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'birds.search_hint'.tr(),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppIcon(AppIcons.search, size: 20),
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _controller.clear();
                    ref.read(birdSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onChanged: (value) {
          ref.read(birdSearchQueryProvider.notifier).state = value;
        },
      ),
    );
  }
}
