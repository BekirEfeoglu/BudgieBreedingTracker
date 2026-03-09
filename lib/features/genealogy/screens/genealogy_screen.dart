import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/depth_chip.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/entity_selector.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/tree_content.dart';

/// Screen with a bird/chick selector, search, bidirectional family tree,
/// family stats, and offspring section.
class GenealogyScreen extends ConsumerStatefulWidget {
  const GenealogyScreen({super.key});

  @override
  ConsumerState<GenealogyScreen> createState() => _GenealogyScreenState();
}

class _GenealogyScreenState extends ConsumerState<GenealogyScreen> {
  @override
  void initState() {
    super.initState();
    initPedigreeDepth(ref);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final chicksAsync = ref.watch(chicksStreamProvider(userId));
    final selection = ref.watch(selectedEntityForTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('genealogy.title'.tr()),
        actions: [
          DepthChip(
            depth: ref.watch(pedigreeDepthProvider),
            onChanged: (value) => setPedigreeDepth(ref, value),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (value) {
              if (value == 'repair') _runRepair(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'repair',
                child: Row(
                  children: [
                    const Icon(LucideIcons.wrench, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text('genealogy.repair_parents'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: birdsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'genealogy.load_error'.tr(),
          onRetry: () {
            ref.invalidate(birdsStreamProvider(userId));
            ref.invalidate(chicksStreamProvider(userId));
          },
        ),
        data: (birds) {
          return chicksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                _buildContent(context, birds, [], selection),
            data: (chicks) =>
                _buildContent(context, birds, chicks, selection),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Bird> birds,
    List<Chick> chicks,
    GenealogySelection? selection,
  ) {
    if (birds.isEmpty && chicks.isEmpty) {
      return EmptyState(
        icon: const AppIcon(AppIcons.genealogy),
        title: 'genealogy.no_birds'.tr(),
        subtitle: 'genealogy.no_birds_subtitle'.tr(),
      );
    }

    // No selection: show full entity list
    if (selection == null) {
      return EntitySelector(
        birds: birds,
        chicks: chicks,
        selection: selection,
        onChanged: (value) {
          ref.read(selectedEntityForTreeProvider.notifier).state = value;
        },
      );
    }

    // Entity selected: show selected chip + tree content
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              prefixIcon: AppIcon(
                selection.isChick ? AppIcons.egg : AppIcons.bird,
                size: 18,
              ),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () {
                  ref.read(selectedEntityForTreeProvider.notifier).state =
                      null;
                },
              ),
            ),
            child: Text(
              _entityName(birds, chicks, selection),
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refreshTree(selection),
            child: TreeContent(
              entityId: selection.id,
              isChick: selection.isChick,
            ),
          ),
        ),
      ],
    );
  }

  String _entityName(
    List<Bird> birds,
    List<Chick> chicks,
    GenealogySelection selection,
  ) {
    if (!selection.isChick) {
      final bird = birds.where((b) => b.id == selection.id).firstOrNull;
      if (bird == null) return '?';
      final ring = bird.ringNumber != null ? ' (${bird.ringNumber})' : '';
      return '${bird.name}$ring';
    }
    final chick = chicks.where((c) => c.id == selection.id).firstOrNull;
    if (chick == null) return '?';
    final name = chick.name ??
        'chicks.unnamed_chick'.tr(
          args: [chick.ringNumber ?? chick.id.substring(0, 6)],
        );
    final ring = chick.ringNumber != null ? ' (${chick.ringNumber})' : '';
    return '$name$ring';
  }

  void _refreshTree(GenealogySelection selection) {
    if (selection.isChick) {
      ref.invalidate(chickAncestorsProvider(selection.id));
    } else {
      ref.invalidate(ancestorsProvider(selection.id));
      ref.invalidate(offspringProvider(selection.id));
    }
  }

  void _runRepair(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('genealogy.repairing'.tr())),
    );

    ref.invalidate(repairOrphanBirdsProvider);
    final result = await ref.read(repairOrphanBirdsProvider.future);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'genealogy.repair_result'.tr(args: [result.toString()]),
        ),
      ),
    );

    if (result > 0) {
      final selection = ref.read(selectedEntityForTreeProvider);
      if (selection != null) _refreshTree(selection);
    }
  }
}
