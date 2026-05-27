part of 'egg_management_screen.dart';

void _showAddEggSheet(
  BuildContext context,
  WidgetRef ref,
  String incubationId,
  List<Egg> existingEggs,
) {
  final nextEggNumber = IncubationCalculator.getNextEggNumber(existingEggs);
  showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      return _AddEggSheetBody(
        incubationId: incubationId,
        nextEggNumber: nextEggNumber,
      );
    },
  );
}

/// Sheet body extracted to a `ConsumerStatefulWidget` so the notes
/// controller is disposed in the standard `dispose()` lifecycle rather
/// than via a fragile post-frame callback chained on `showAppBottomSheet`
/// completion. The previous pattern leaked across re-open sequences when
/// the user dismissed without tapping Add and reopened the sheet within
/// the same frame.
class _AddEggSheetBody extends ConsumerStatefulWidget {
  const _AddEggSheetBody({
    required this.incubationId,
    required this.nextEggNumber,
  });

  final String incubationId;
  final int nextEggNumber;

  @override
  ConsumerState<_AddEggSheetBody> createState() => _AddEggSheetBodyState();
}

class _AddEggSheetBodyState extends ConsumerState<_AddEggSheetBody> {
  /// Lay date is stored as UTC midnight so day-difference math against
  /// species hatch offsets stays stable (see datetime-format.md). The
  /// picker emits a local-midnight DateTime; we normalize here.
  DateTime _layDate = date_utils.DateUtils.utcMidnight(DateTime.now());
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      eggActionsProvider.select((s) => s.isLoading),
    );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'eggs.add_new_egg'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              initialValue: '${widget.nextEggNumber}',
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'eggs.egg_number'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.tag),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DatePickerField(
              label: 'eggs.lay_date'.tr(),
              value: _layDate,
              onChanged: (date) => setState(
                () => _layDate = date_utils.DateUtils.utcMidnight(date),
              ),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialEntryMode: DatePickerEntryMode.input,
              dateFormatter: ref.read(dateFormatProvider).formatter(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'common.notes_optional'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.stickyNote),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      await ref.read(eggActionsProvider.notifier).addEgg(
                            incubationId: widget.incubationId,
                            layDate: _layDate,
                            eggNumber: widget.nextEggNumber,
                            notes: _notesController.text.isEmpty
                                ? null
                                : _notesController.text,
                          );
                      // Only close the sheet on success. If addEgg
                      // populated state.error (e.g. invalid_incubation),
                      // the parent screen's listener surfaces the toast —
                      // keeping the sheet open lets the user retry.
                      final error = ref.read(eggActionsProvider).error;
                      if (error == null && navigator.mounted) {
                        navigator.pop();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.add'.tr()),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteEgg(
  BuildContext context,
  WidgetRef ref,
  Egg egg,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'eggs.delete_egg'.tr(),
    message: 'eggs.delete_confirm_number'.tr(
      namedArgs: {'number': '${egg.eggNumber ?? '?'}'},
    ),
    confirmLabel: 'common.delete'.tr(),
    isDestructive: true,
  );
  if (!context.mounted) return;
  if (confirmed == true) {
    ref.read(eggActionsProvider.notifier).deleteEgg(egg.id);
  }
}
