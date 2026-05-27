part of 'egg_management_screen.dart';

void _showAddEggSheet(
  BuildContext context,
  WidgetRef ref,
  String incubationId,
  List<Egg> existingEggs,
) {
  DateTime layDate = DateTime.now();
  final nextEggNumber = IncubationCalculator.getNextEggNumber(existingEggs);
  final notesController = TextEditingController();

  showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
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
                    initialValue: '$nextEggNumber',
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
                    value: layDate,
                    onChanged: (date) => setSheetState(() => layDate = date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialEntryMode: DatePickerEntryMode.input,
                    dateFormatter: ref.read(dateFormatProvider).formatter(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'common.notes_optional'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(LucideIcons.stickyNote),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Consumer(
                    builder: (context, sheetRef, _) {
                      final isLoading = sheetRef.watch(
                        eggActionsProvider.select((s) => s.isLoading),
                      );
                      return FilledButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await sheetRef
                                    .read(eggActionsProvider.notifier)
                                    .addEgg(
                                      incubationId: incubationId,
                                      layDate: layDate,
                                      eggNumber: nextEggNumber,
                                      notes: notesController.text.isEmpty
                                          ? null
                                          : notesController.text,
                                    );
                                // Only close the sheet on success. If addEgg
                                // populated state.error (e.g. invalid_incubation,
                                // unknown error), the parent screen's listener
                                // surfaces the error toast — keeping the sheet
                                // open lets the user correct their input.
                                final error = sheetRef
                                    .read(eggActionsProvider)
                                    .error;
                                if (error == null && navigator.mounted) {
                                  navigator.pop();
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('common.add'.tr()),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => notesController.dispose(),
    );
  });
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
