import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Search bar for filtering breeding pairs by bird name or ring number.
class BreedingSearchBar extends ConsumerStatefulWidget {
  const BreedingSearchBar({super.key});

  @override
  ConsumerState<BreedingSearchBar> createState() => _BreedingSearchBarState();
}

class _BreedingSearchBarState extends ConsumerState<BreedingSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(breedingSearchQueryProvider);

    // Sync the controller when the query is cleared externally (e.g. a filter
    // reset elsewhere). Done via ref.listen rather than a post-frame callback
    // in build so the controller mutation happens exactly once per change,
    // outside the build phase, with no listener-loop risk.
    ref.listen<String>(breedingSearchQueryProvider, (_, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'breeding.search_hint'.tr(),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppIcon(AppIcons.search, size: 20),
          ),
          suffixIcon: query.isNotEmpty
              ? AppIconButton(
                  icon: const Icon(LucideIcons.x),
                  semanticLabel: 'common.clear'.tr(),
                  onPressed: () {
                    _debounce?.cancel();
                    _controller.clear();
                    ref.read(breedingSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onChanged: (value) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            ref.read(breedingSearchQueryProvider.notifier).state = value;
          });
        },
      ),
    );
  }
}
