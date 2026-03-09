import 'package:flutter/material.dart';

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}
