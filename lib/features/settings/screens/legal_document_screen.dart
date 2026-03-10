import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final content = _localizedContent(type, locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == LegalDocumentType.privacyPolicy
              ? 'settings.privacy_policy'.tr()
              : 'settings.terms'.tr(),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            content.lastUpdated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final section in content.sections) ...[
            _LegalSectionCard(section: section),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section});

  final _LegalSection section;

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
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(section.body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _LegalContent {
  const _LegalContent({
    required this.lastUpdated,
    required this.sections,
  });

  final String lastUpdated;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

_LegalContent _localizedContent(LegalDocumentType type, String localeCode) {
  switch (localeCode) {
    case 'de':
      return _deContent(type);
    case 'tr':
      return _trContent(type);
    default:
      return _enContent(type);
  }
}

_LegalContent _trContent(LegalDocumentType type) {
  if (type == LegalDocumentType.privacyPolicy) {
    return const _LegalContent(
      lastUpdated: 'Son güncelleme: 10 Mart 2026',
      sections: [
        _LegalSection(
          title: 'Toplanan Veriler',
          body:
              'Uygulama, kuş kayıtları, üreme, kuluçka, sağlık ve bildirim tercihleri gibi verileri yalnızca hizmetin sunulması için işler.',
        ),
        _LegalSection(
          title: 'Veri Kullanımı',
          body:
              'Veriler, uygulama özelliklerini çalıştırmak, senkronizasyon sağlamak ve kullanıcı deneyimini iyileştirmek amacıyla kullanılır.',
        ),
        _LegalSection(
          title: 'Veri Güvenliği',
          body:
              'Verilerinizin güvenliği için teknik ve idari kontroller uygulanır. Ancak hiçbir sistemin tamamen risksiz olmadığı unutulmamalıdır.',
        ),
        _LegalSection(
          title: 'İletişim',
          body: 'Gizlilik sorularınız için: support@budgiebreedingtracker.online',
        ),
      ],
    );
  }

  return const _LegalContent(
    lastUpdated: 'Son güncelleme: 10 Mart 2026',
    sections: [
      _LegalSection(
        title: 'Kabul',
        body:
            'Uygulamayı kullanarak kullanım şartlarını kabul etmiş olursunuz. Şartlar zaman içinde güncellenebilir.',
      ),
      _LegalSection(
        title: 'Hesap Sorumluluğu',
        body:
            'Hesap bilgilerinizin güvenliğinden siz sorumlusunuz. Şüpheli bir durumda parolanızı güncelleyin.',
      ),
      _LegalSection(
        title: 'Abonelik ve Ödemeler',
        body:
            'Premium satın alımları ilgili uygulama mağazası kurallarına tabidir. İptal ve iade süreçleri mağaza politikalarıyla yürütülür.',
      ),
      _LegalSection(
        title: 'İletişim',
        body: 'Şartlarla ilgili sorular için: support@budgiebreedingtracker.online',
      ),
    ],
  );
}

_LegalContent _enContent(LegalDocumentType type) {
  if (type == LegalDocumentType.privacyPolicy) {
    return const _LegalContent(
      lastUpdated: 'Last updated: March 10, 2026',
      sections: [
        _LegalSection(
          title: 'Data We Collect',
          body:
              'The app processes breeding records, birds, chicks, health data, reminders, and preference settings required to deliver core functionality.',
        ),
        _LegalSection(
          title: 'How Data Is Used',
          body:
              'Your data is used to provide app features, backup/sync operations, and product quality improvements.',
        ),
        _LegalSection(
          title: 'Security',
          body:
              'Reasonable technical and organizational safeguards are applied, but no system can be guaranteed as completely risk-free.',
        ),
        _LegalSection(
          title: 'Contact',
          body: 'Privacy questions: support@budgiebreedingtracker.online',
        ),
      ],
    );
  }

  return const _LegalContent(
    lastUpdated: 'Last updated: March 10, 2026',
    sections: [
      _LegalSection(
        title: 'Acceptance',
        body:
            'By using the app, you agree to these terms. Terms may be updated from time to time.',
      ),
      _LegalSection(
        title: 'Account Responsibility',
        body:
            'You are responsible for keeping your account credentials secure and up to date.',
      ),
      _LegalSection(
        title: 'Subscriptions and Billing',
        body:
            'Premium purchases are governed by the relevant app store terms. Refund and cancellation are subject to store policy.',
      ),
      _LegalSection(
        title: 'Contact',
        body: 'Terms questions: support@budgiebreedingtracker.online',
      ),
    ],
  );
}

_LegalContent _deContent(LegalDocumentType type) {
  if (type == LegalDocumentType.privacyPolicy) {
    return const _LegalContent(
      lastUpdated: 'Zuletzt aktualisiert: 10. März 2026',
      sections: [
        _LegalSection(
          title: 'Erfasste Daten',
          body:
              'Die App verarbeitet Brutdaten, Vogel- und Gesundheitsdaten, Erinnerungen und Einstellungen, um die Kernfunktionen bereitzustellen.',
        ),
        _LegalSection(
          title: 'Verwendungszweck',
          body:
              'Die Daten werden zur Bereitstellung von Funktionen, für Sicherung/Synchronisierung und zur Verbesserung der Produktqualität verwendet.',
        ),
        _LegalSection(
          title: 'Sicherheit',
          body:
              'Es werden angemessene technische und organisatorische Schutzmaßnahmen eingesetzt, jedoch kann kein System vollständige Sicherheit garantieren.',
        ),
        _LegalSection(
          title: 'Kontakt',
          body: 'Fragen zum Datenschutz: support@budgiebreedingtracker.online',
        ),
      ],
    );
  }

  return const _LegalContent(
    lastUpdated: 'Zuletzt aktualisiert: 10. März 2026',
    sections: [
      _LegalSection(
        title: 'Akzeptanz',
        body:
            'Mit der Nutzung der App akzeptieren Sie diese Bedingungen. Die Bedingungen können aktualisiert werden.',
      ),
      _LegalSection(
        title: 'Kontoverantwortung',
        body:
            'Sie sind für die Sicherheit Ihrer Zugangsdaten verantwortlich und sollten diese aktuell halten.',
      ),
      _LegalSection(
        title: 'Abonnements und Zahlungen',
        body:
            'Premium-Käufe unterliegen den Bedingungen des jeweiligen App-Stores. Erstattungen und Kündigungen richten sich nach dessen Richtlinien.',
      ),
      _LegalSection(
        title: 'Kontakt',
        body: 'Fragen zu den Bedingungen: support@budgiebreedingtracker.online',
      ),
    ],
  );
}

