import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';

class SettingsOption<T> {
  const SettingsOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? icon;
}

class SettingsSelectionTile<T> extends StatelessWidget {
  const SettingsSelectionTile({
    super.key,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    this.icon,
    this.dialogTitle,
  });

  final String title;
  final T currentValue;
  final List<SettingsOption<T>> options;
  final ValueChanged<T> onChanged;
  final Widget? icon;
  final String? dialogTitle;

  @override
  Widget build(BuildContext context) {
    final currentOption = options.firstWhere(
      (o) => o.value == currentValue,
      orElse: () => options.first,
    );

    return ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(currentOption.label),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () => _showSelectionDialog(context),
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showDialog<T>(
      context: context,
      builder: (dialogCtx) => _SelectionDialog<T>(
        title: dialogTitle ?? title,
        options: options,
        currentValue: currentValue,
        onChanged: (val) {
          onChanged(val);
          Navigator.of(dialogCtx).pop();
        },
      ),
    );
  }
}

class _SelectionDialog<T> extends StatefulWidget {
  const _SelectionDialog({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onChanged,
  });

  final String title;
  final List<SettingsOption<T>> options;
  final T currentValue;
  final ValueChanged<T> onChanged;

  @override
  State<_SelectionDialog<T>> createState() => _SelectionDialogState<T>();
}

class _SelectionDialogState<T> extends State<_SelectionDialog<T>> {
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      content: RadioGroup<T>(
        groupValue: _selectedValue,
        onChanged: (T? val) {
          if (val != null) {
            setState(() => _selectedValue = val);
            widget.onChanged(val);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.map((option) {
            return RadioListTile<T>(
              title: Text(option.label),
              subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
              secondary: option.icon,
              value: option.value,
            );
          }).toList(),
        ),
      ),
    );
  }
}
