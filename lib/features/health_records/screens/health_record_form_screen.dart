import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_form_fields.dart';
import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';

/// Form screen for creating/editing a health record.
class HealthRecordFormScreen extends ConsumerStatefulWidget {
  final String? editRecordId;
  final String? preselectedBirdId;

  const HealthRecordFormScreen({
    super.key,
    this.editRecordId,
    this.preselectedBirdId,
  });

  @override
  ConsumerState<HealthRecordFormScreen> createState() =>
      _HealthRecordFormScreenState();
}

class _HealthRecordFormScreenState
    extends ConsumerState<HealthRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleFieldKey = GlobalKey();
  final _titleFocusNode = FocusNode();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();
  final _costController = TextEditingController();

  HealthRecordType _type = HealthRecordType.checkup;
  DateTime _date = DateTime.now();
  DateTime? _followUpDate;
  String? _birdId;
  String? _chickId;
  bool _isEdit = false;
  bool _didPopulateFromExisting = false;
  HealthRecord? _existingRecord;
  bool _savedSuccessfully = false;

  bool get _isDirty {
    if (_savedSuccessfully) return false;
    if (_isEdit) {
      final existing = _existingRecord;
      // Not populated yet (loading / pre post-frame) — assume dirty so a back
      // tap can't silently drop an in-progress edit. Mirrors the bird/chick/
      // breeding forms; once populated, real field comparison applies.
      if (existing == null) return true;
      // Weight/cost are compared against the same `.toString()` representation
      // used to populate the controllers (see _populateFromExisting), so an
      // untouched numeric field reads as clean.
      final existingWeight = existing.weight != null
          ? existing.weight.toString()
          : '';
      final existingCost = existing.cost != null
          ? existing.cost.toString()
          : '';
      return _titleController.text != existing.title ||
          _type != existing.type ||
          _date != existing.date ||
          _birdId != existing.birdId ||
          _chickId != existing.chickId ||
          _descriptionController.text != (existing.description ?? '') ||
          _treatmentController.text != (existing.treatment ?? '') ||
          _vetController.text != (existing.veterinarian ?? '') ||
          _notesController.text != (existing.notes ?? '') ||
          _weightController.text != existingWeight ||
          _costController.text != existingCost ||
          _followUpDate != existing.followUpDate;
    }
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _treatmentController.text.isNotEmpty ||
        _vetController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _costController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _birdId = widget.preselectedBirdId;
    _isEdit = widget.editRecordId != null;
  }

  void _populateFromExisting(HealthRecord record) {
    _existingRecord = record;
    // Controllers self-notify on .text assignment.
    _titleController.text = record.title;
    _descriptionController.text = record.description ?? '';
    _treatmentController.text = record.treatment ?? '';
    _vetController.text = record.veterinarian ?? '';
    _notesController.text = record.notes ?? '';
    _weightController.text = record.weight != null
        ? record.weight.toString()
        : '';
    _costController.text = record.cost != null ? record.cost.toString() : '';
    // The type/date/follow-up/animal selectors are plain fields that only
    // repaint on setState — without this the edit form shows default values
    // until an unrelated rebuild (e.g. the birds stream emitting) happens to
    // fire, and can latch the wrong selection if that lands first.
    setState(() {
      _type = record.type;
      _date = record.date;
      _birdId = record.birdId;
      _chickId = record.chickId;
      _followUpDate = record.followUpDate;
      _didPopulateFromExisting = true;
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _treatmentController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(healthRecordFormStateProvider);
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final chicksAsync = ref.watch(chicksStreamProvider(userId));

    ref.listen<HealthRecordFormState>(healthRecordFormStateProvider, (
      _,
      state,
    ) {
      if (!mounted) return;
      if (state.isSuccess) {
        _savedSuccessfully = true;
        ref.read(healthRecordFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    if (_isEdit) {
      final editId = widget.editRecordId!;
      final existingAsync = ref.watch(healthRecordByIdProvider(editId));

      return existingAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text('common.loading'.tr())),
          body: const LoadingState(),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text('common.error'.tr())),
          body: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(healthRecordByIdProvider(editId)),
          ),
        ),
        data: (existing) {
          if (existing == null) {
            return Scaffold(
              appBar: AppBar(title: Text('common.not_found'.tr())),
              body: ErrorState(
                message: 'health_records.not_found'.tr(),
                onRetry: () => ref.invalidate(healthRecordByIdProvider(editId)),
              ),
            );
          }

          if (!_didPopulateFromExisting) {
            // Defer controller mutation to post-frame so we don't trigger
            // setState/text changes while the build is in progress
            // (anti-pattern: side effects in build).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _didPopulateFromExisting) return;
              _populateFromExisting(existing);
            });
          }
          return _buildFormScaffold(formState, birdsAsync, chicksAsync);
        },
      );
    }

    return _buildFormScaffold(formState, birdsAsync, chicksAsync);
  }

  Widget _buildFormScaffold(
    HealthRecordFormState formState,
    AsyncValue<dynamic> birdsAsync,
    AsyncValue<dynamic> chicksAsync,
  ) {
    return UnsavedChangesScope(
      isDirty: _isDirty,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit
                ? 'health_records.edit_record'.tr()
                : 'health_records.new_record'.tr(),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HealthRecordFormFields(
                      titleFieldKey: _titleFieldKey,
                      titleFocusNode: _titleFocusNode,
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      treatmentController: _treatmentController,
                      vetController: _vetController,
                      notesController: _notesController,
                      weightController: _weightController,
                      costController: _costController,
                      type: _type,
                      date: _date,
                      followUpDate: _followUpDate,
                      birdId: _birdId,
                      chickId: _chickId,
                      birds: birdsAsync.value ?? [],
                      chicks: chicksAsync.value ?? [],
                      isAnimalsLoading:
                          birdsAsync.isLoading || chicksAsync.isLoading,
                      dateFormatter: ref.watch(dateFormatProvider).formatter(),
                      onTypeChanged: (t) => setState(() => _type = t),
                      onDateChanged: (d) => setState(() => _date = d),
                      onFollowUpDateChanged: (d) =>
                          setState(() => _followUpDate = d),
                      onBirdChanged: (v) => setState(() => _birdId = v),
                      onChickChanged: (v) => setState(() => _chickId = v),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Submit
                    PrimaryButton(
                      label: _isEdit
                          ? 'common.update'.tr()
                          : 'common.save'.tr(),
                      isLoading: formState.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_titleController.text.trim().isEmpty) {
        _titleFocusNode.requestFocus();
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final titleContext = _titleFieldKey.currentContext;
        if (titleContext != null && titleContext.mounted) {
          await Scrollable.ensureVisible(
            titleContext,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }
      return;
    }
    AppHaptics.lightImpact();

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(healthRecordFormStateProvider.notifier);

    final weight = _weightController.text.trim().isNotEmpty
        ? double.tryParse(_weightController.text.trim())
        : null;
    final cost = _costController.text.trim().isNotEmpty
        ? double.tryParse(_costController.text.trim())
        : null;

    if (_isEdit && _existingRecord != null) {
      notifier.updateRecord(
        _existingRecord!.copyWith(
          title: _titleController.text.trim(),
          type: _type,
          date: _date,
          birdId: _birdId,
          chickId: _chickId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          treatment: _treatmentController.text.isEmpty
              ? null
              : _treatmentController.text.trim(),
          veterinarian: _vetController.text.isEmpty
              ? null
              : _vetController.text.trim(),
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          weight: weight,
          cost: cost,
          followUpDate: _followUpDate,
        ),
      );
    } else {
      notifier.createRecord(
        userId: userId,
        title: _titleController.text.trim(),
        type: _type,
        date: _date,
        birdId: _birdId,
        chickId: _chickId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        treatment: _treatmentController.text.isEmpty
            ? null
            : _treatmentController.text.trim(),
        veterinarian: _vetController.text.isEmpty
            ? null
            : _vetController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        weight: weight,
        cost: cost,
        followUpDate: _followUpDate,
      );
    }
  }
}
