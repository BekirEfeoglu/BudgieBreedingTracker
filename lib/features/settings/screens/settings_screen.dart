import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../widgets/about_section.dart';
import '../widgets/accessibility_section.dart';
import '../widgets/data_storage_section.dart';
import '../widgets/display_section.dart';
import '../widgets/language_section.dart';
import '../widgets/notifications_section.dart';
import '../widgets/privacy_security_section.dart';

/// Application settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
        children: const [
          DisplaySection(),
          LanguageSection(),
          AccessibilitySection(),
          NotificationsSection(),
          DataStorageSection(),
          PrivacySecuritySection(),
          AboutSection(),
        ],
      ),
    );
  }
}
