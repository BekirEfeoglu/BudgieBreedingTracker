import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_spacing.dart';

/// Google and Apple sign-in buttons for the auth screens.
class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.isLoading = false,
  });

  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final bool isLoading;

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  bool _googlePressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'common.or'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Google button
        _PressScaleButton(
          isPressed: _googlePressed,
          onTapDown: widget.isLoading
              ? null
              : () => setState(() => _googlePressed = true),
          onTapUp: () => setState(() => _googlePressed = false),
          onTap: widget.isLoading ? null : widget.onGoogleTap,
          child: OutlinedButton.icon(
            onPressed: widget.isLoading ? null : widget.onGoogleTap,
            icon: SvgPicture.asset(
              'assets/icons/general/google_logo.svg',
              width: 18,
              height: 18,
            ),
            label: Text('auth.sign_in_with_google'.tr()),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              minimumSize: const Size(
                double.infinity,
                AppSpacing.touchTargetMd,
              ),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Apple button
        SizedBox(
          width: double.infinity,
          child: SignInWithAppleButton(
            onPressed: widget.isLoading ? null : widget.onAppleTap,
            text: 'auth.sign_in_with_apple'.tr(),
            height: AppSpacing.touchTargetMd,
            style: theme.brightness == Brightness.dark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.black,
          ),
        ),
      ],
    );
  }
}

/// Basılı tutulduğunda hafifçe küçülen wrapper widget.
class _PressScaleButton extends StatelessWidget {
  const _PressScaleButton({
    required this.isPressed,
    required this.child,
    required this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  final bool isPressed;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapUp,
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: child,
      ),
    );
  }
}
