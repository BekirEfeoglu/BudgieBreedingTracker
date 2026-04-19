import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';

/// Styled text field for auth forms with optional password visibility toggle.
///
/// [prefixIcon] accepts any [Widget] – use [Icon] for Material/Lucide icons
/// or [AppIcon] for custom SVG assets.
class AuthFormField extends StatefulWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.focusNode,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  bool _obscure = true;

  // iOS keyboard fix: ensure Flutter's UIWindow is the key window before
  // UIKit tries to show the software keyboard. Without this, a third-party
  // SDK that creates its own UIWindow (e.g. google_mobile_ads UMP) can steal
  // key-window status — causing becomeFirstResponder() to silently fail so
  // the keyboard never appears.
  static const _iosKeyboardChannel = MethodChannel(
    'com.budgie/ios_keyboard_fix',
  );

  Future<void> _ensureFlutterWindowKey() async {
    if (!Platform.isIOS) return;
    try {
      await _iosKeyboardChannel.invokeMethod<void>('makeFlutterWindowKey');
    } catch (_) {
      // Channel not ready yet or running on non-iOS — silently ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: _ensureFlutterWindowKey,
      validator: widget.validator,
      enabled: widget.enabled,
      autofillHints: widget.enabled ? widget.autofillHints : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: widget.prefixIcon,
              )
            : null,
        suffixIcon: widget.isPassword
            ? AppIconButton(
                icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
                tooltip: _obscure
                    ? 'auth.show_password'.tr()
                    : 'auth.hide_password'.tr(),
                semanticLabel: _obscure
                    ? 'auth.show_password'.tr()
                    : 'auth.hide_password'.tr(),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
