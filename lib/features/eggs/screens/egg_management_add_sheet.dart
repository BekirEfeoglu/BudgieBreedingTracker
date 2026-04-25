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
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(eggActionsProvider.notifier)
                          .addEgg(
                            incubationId: incubationId,
                            layDate: layDate,
                            eggNumber: nextEggNumber,
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          );
                      Navigator.of(context).pop();
                    },
                    child: Text('common.add'.tr()),
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
  if (confirmed == true) {
    ref.read(eggActionsProvider.notifier).deleteEgg(egg.id);
  }
}
