import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Search bar for filtering birds by name, ring number, or cage number.
class BirdSearchBar extends ConsumerStatefulWidget {
  const BirdSearchBar({super.key});

  @override
  ConsumerState<BirdSearchBar> createState() => _BirdSearchBarState();
}

class _BirdSearchBarState extends ConsumerState<BirdSearchBar> {
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
    final query = ref.watch(birdSearchQueryProvider);

    // Sync the controller when the query is cleared externally (e.g. a
    // filter reset). Done as a listen side-effect — mutating the controller
    // during build can trigger listener loops, and a post-frame callback in
    // build re-arms on every rebuild. listen fires only on actual changes.
    ref.listen<String>(birdSearchQueryProvider, (_, next) {
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
          hintText: 'birds.search_hint'.tr(),
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
                    ref.read(birdSearchQueryProvider.notifier).state = '';
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
            ref.read(birdSearchQueryProvider.notifier).state = value;
          });
        },
      ),
    );
  }
}
