import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
  communityGuidelines,
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (type) {
            LegalDocumentType.privacyPolicy => 'settings.privacy_policy'.tr(),
            LegalDocumentType.termsOfService => 'settings.terms'.tr(),
            LegalDocumentType.communityGuidelines =>
              'legal.community_guidelines_title'.tr(),
          },
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'legal.last_updated'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final section in sections) ...[
            _LegalSectionCard(
              title: section.$1,
              body: section.$2,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _buildSections() {
    if (type == LegalDocumentType.privacyPolicy) {
      return [
        ('legal.privacy_collected_title'.tr(), 'legal.privacy_collected_body'.tr()),
        ('legal.privacy_usage_title'.tr(), 'legal.privacy_usage_body'.tr()),
        ('legal.privacy_ads_title'.tr(), 'legal.privacy_ads_body'.tr()),
        ('legal.privacy_security_title'.tr(), 'legal.privacy_security_body'.tr()),
        ('legal.privacy_contact_title'.tr(), 'legal.privacy_contact_body'.tr()),
      ];
    }

    if (type == LegalDocumentType.communityGuidelines) {
      return [
        ('legal.cg_conduct_title'.tr(), 'legal.cg_conduct_body'.tr()),
        ('legal.cg_content_title'.tr(), 'legal.cg_content_body'.tr()),
        ('legal.cg_enforcement_title'.tr(), 'legal.cg_enforcement_body'.tr()),
        ('legal.cg_reporting_title'.tr(), 'legal.cg_reporting_body'.tr()),
      ];
    }

    return [
      ('legal.terms_acceptance_title'.tr(), 'legal.terms_acceptance_body'.tr()),
      ('legal.terms_account_title'.tr(), 'legal.terms_account_body'.tr()),
      ('legal.terms_subscription_title'.tr(), 'legal.terms_subscription_body'.tr()),
      ('legal.terms_contact_title'.tr(), 'legal.terms_contact_body'.tr()),
    ];
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
