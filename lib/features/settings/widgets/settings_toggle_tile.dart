import 'package:flutter/material.dart';

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = value
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      secondary: icon != null
          ? IconTheme(
              data: IconThemeData(size: 24, color: iconColor),
              child: icon!,
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
