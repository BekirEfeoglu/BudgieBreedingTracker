import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Default date format pattern used when no [dateFormatter] is provided.
const _defaultDatePattern = 'dd.MM.yyyy';

/// A read-only text field that opens a date picker on tap.
class DatePickerField extends StatefulWidget {
  final DateTime? value;
  final String label;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final DatePickerEntryMode initialEntryMode;

  /// Optional date formatter. When omitted, defaults to `dd.MM.yyyy`.
  final DateFormat? dateFormatter;

  const DatePickerField({
    super.key,
    this.value,
    required this.label,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.isRequired = true,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.dateFormatter,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;

  String _formattedValue(DateTime? value) {
    final formatter = widget.dateFormatter ?? DateFormat(_defaultDatePattern);
    return value != null ? formatter.format(value) : '';
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formattedValue(widget.value));
  }

  @override
  void didUpdateWidget(DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.dateFormatter == widget.dateFormatter) {
      return;
    }
    // Deferred to a post-frame callback: updating the controller's value
    // notifies the wrapping FormFieldState, which asks the ancestor Form to
    // rebuild. The ancestor Form has already finished building earlier in
    // this same top-down pass (parents build before children), so re-dirtying
    // it synchronously here — even from didUpdateWidget, still mid-pass for
    // this frame — throws "setState() or markNeedsBuild() called during
    // build". Running it after the frame completes avoids that entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final formattedValue = _formattedValue(widget.value);
      if (_controller.text != formattedValue) {
        _controller.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }
    });
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
        suffixIcon: const Padding(
          padding: EdgeInsets.all(14),
          child: AppIcon(AppIcons.calendar, size: 20),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
          maxWidth: 56,
          maxHeight: 56,
        ),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.value ?? DateTime.now(),
          firstDate: widget.firstDate ?? DateTime(2020),
          lastDate:
              widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
          initialEntryMode: widget.initialEntryMode,
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
