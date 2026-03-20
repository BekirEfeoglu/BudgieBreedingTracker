import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_brand_title.dart';
import '../../auth/providers/auth_providers.dart';

/// Splash screen shown while the app initializes.
/// Displays animated logo, progress messages, and error fallback UI.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInit = ref.watch(appInitializationProvider);

    return Scaffold(
      body: appInit.when(
        loading: () => const _LoadingBody(),
        error: (error, _) => const _ErrorBody(),
        data: (_) => const _LoadingBody(),
      ),
    );
  }
}

/// Animated loading state with logo and progress message.
class _LoadingBody extends ConsumerStatefulWidget {
  const _LoadingBody();

  @override
  ConsumerState<_LoadingBody> createState() => _LoadingBodyState();
}

class _LoadingBodyState extends ConsumerState<_LoadingBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _imagePrecached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagePrecached) {
      _imagePrecached = true;
      precacheImage(const AssetImage('assets/images/budgie-icon.png'), context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: const AppBrandTitle(size: AppBrandSize.large),
      ),
    );
  }
}

/// Error state with retry and continue offline buttons.
class _ErrorBody extends ConsumerWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.offline,
                size: 40,
                color: AppColors.error,
                semanticsLabel: 'Offline',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Error title
            Text(
              'splash.error_title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Error message
            Text(
              'splash.error_message'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Retry button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ref.invalidate(appInitializationProvider),
                icon: const AppIcon(AppIcons.sync),
                label: Text('splash.retry'.tr()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Continue offline button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(initSkippedProvider.notifier).state = true;
                },
                child: Text('splash.continue_offline'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
