import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

/// A read-only text field that opens a date picker on tap.
class DatePickerField extends ConsumerStatefulWidget {
  final DateTime? value;
  final String label;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;

  const DatePickerField({
    super.key,
    this.value,
    required this.label,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.isRequired = true,
  });

  @override
  ConsumerState<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends ConsumerState<DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = ref.watch(dateFormatProvider).formatter();
    final formattedValue =
        widget.value != null ? formatter.format(widget.value!) : '';
    if (_controller.text != formattedValue) {
      _controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }

    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: const AppIcon(AppIcons.calendar, size: 20),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.value ?? DateTime.now(),
          firstDate: widget.firstDate ?? DateTime(2020),
          lastDate:
              widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          widget.onChanged(picked);
        }
      },
      validator: widget.isRequired
          ? (v) {
              if (v == null || v.isEmpty) {
                return 'validation.field_required'.tr(args: [widget.label]);
              }
              return null;
            }
          : null,
    );
  }
}
