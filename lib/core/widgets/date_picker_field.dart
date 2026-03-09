import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// A read-only text field that opens a date picker on tap.
class DatePickerField extends StatefulWidget {
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
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;
  final _formatter = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? _formatter.format(widget.value!) : '',
    );
  }

  @override
  void didUpdateWidget(covariant DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text =
          widget.value != null ? _formatter.format(widget.value!) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
