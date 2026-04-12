part of 'two_factor_setup_screen.dart';

extension _TwoFactorSetupViews on _TwoFactorSetupScreenState {
  Widget _buildErrorView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(
          LucideIcons.alertTriangle,
          size: 64,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'auth.2fa_retry'.tr(),
          onPressed: _startEnrollment,
        ),
      ],
    );
  }

  Widget _buildSetupView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.lg),
        AppIcon(AppIcons.twoFactor, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'auth.2fa_scan_qr'.tr(),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'auth.2fa_scan_qr_hint'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),

        if (_qrCode != null) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth * 0.55).clamp(160.0, 260.0);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: SvgPicture.string(
                  _qrCode!,
                  width: qrSize,
                  height: qrSize,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (_secret != null) ...[
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  Text(
                    'auth.2fa_manual_key'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    _secret!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secret!));
                      ActionFeedbackService.show('auth.2fa_key_copied'.tr());
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: Text('auth.2fa_copy_key'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),

        Text('auth.2fa_enter_code'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        OtpInputField(onCompleted: _verifyCode),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],

        if (_isVerifying) ...[
          const SizedBox(height: AppSpacing.lg),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        const Icon(LucideIcons.checkCircle, size: 64, color: AppColors.success),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'auth.2fa_enabled'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'auth.2fa_enabled_desc'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'common.done'.tr(),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
