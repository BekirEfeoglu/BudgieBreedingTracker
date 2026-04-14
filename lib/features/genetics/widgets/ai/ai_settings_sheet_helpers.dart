part of 'ai_settings_sheet.dart';

/// Helper widgets for [AiSettingsSheet] — model recommendations and hint strip.
extension _AiSettingsHelpers on _AiSettingsSheetState {
  Widget _buildModelRecommendations(ThemeData theme) {
    const models = [
      (
        id: 'google/gemma-4-26b-a4b-it:free',
        name: 'Gemma 4 26B',
        tag: 'genetics.ai_model_free',
        vision: true,
      ),
      (
        id: 'meta-llama/llama-4-scout:free',
        name: 'Llama 4 Scout',
        tag: 'genetics.ai_model_free',
        vision: true,
      ),
      (
        id: 'google/gemini-2.0-flash-001',
        name: 'Gemini 2.0 Flash',
        tag: 'genetics.ai_model_paid',
        vision: true,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'genetics.ai_recommended_models'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...models.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: () {
                  _modelController.text = m.id;
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        m.vision ? LucideIcons.eye : LucideIcons.type,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          m.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: m.tag.contains('free')
                              ? AppColors.aiFeatureMutation
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          m.tag.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: m.tag.contains('free')
                                ? AppColors.aiFeatureMutation
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintStrip(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
