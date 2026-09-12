import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppTheme.getTextPrimary(context)),
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.shield_tick, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _privacyText,
              style: TextStyle(fontSize: 14, height: 1.5, color: AppTheme.getTextPrimary(context)),
            ),
            const SizedBox(height: 24),
            Text(
              'For questions about privacy or data handling, contact university support via the Support option in the app.',
              style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}

const String _privacyText = '''
SMART CLASSCATCH — Privacy Policy

Last updated: 2026-07-03

Introduction
This Privacy Policy explains how SMART CLASSCATCH collects, uses, shares, and protects information when you use the SMART CLASSCATCH mobile and web applications ("App"). By using the App you agree to the practices described in this policy.

1. Information We Collect
- Profile information: name, email, admission number, phone number.
- Usage data: events, app preferences, and analytics necessary to maintain and improve the Service.
- Portal sync data: when using Portal Sync we request your portal credentials to fetch your registered units; credentials are transmitted to the backend for a single request and not persisted on the client.

2. How We Use Information
- To provide and personalize the Service (timetables, notifications, portal sync).
- To diagnose and fix issues, and to analyze usage for improvements.
- To comply with legal obligations and protect users.

3. Data Sharing
- We do not sell personal data. Data may be shared with third-party service providers (e.g., analytics, auth providers) subject to their own privacy terms.

4. Data Retention
- Data is retained according to university policies and applicable law. You can request deletion via the university or app support channels where supported.

5. Security
- We employ reasonable technical and administrative measures to protect data. No system is fully secure; report suspected breaches to support immediately.

6. Your Choices
- You can manage certain preferences in the App (e.g., notifications, language, theme).
- To request account deletion or export, contact university support or follow account flows where available.

7. Changes
- We may update this Privacy Policy. Continued use after changes constitutes acceptance of the updated policy.

Contact
For privacy questions contact university support through the App's Support option.

''';
