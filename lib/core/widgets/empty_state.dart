import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'animations/pulse_animation.dart';
import 'animations/slide_fade_animation.dart';

class EmptyState extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: SlideFadeAnimation(
          startOffset: const Offset(0, 0.2),
          duration: const Duration(milliseconds: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseAnimation(
                lowerBound: 0.95,
                upperBound: 1.05,
                duration: const Duration(milliseconds: 1500),
                child: IconTheme(
                  data: IconThemeData(
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
