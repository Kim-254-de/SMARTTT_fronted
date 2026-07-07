import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppTheme.getTextPrimary(context)),
        title: Text(
          'Terms & Conditions',
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
                Icon(Iconsax.info_circle, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _termsText,
              style: TextStyle(fontSize: 14, height: 1.5, color: AppTheme.getTextPrimary(context)),
            ),
            const SizedBox(height: 24),
            Text(
              'If you have questions about these terms, please contact university support.',
              style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}

const String _termsText = '''
SMARTTT — Terms & Conditions

Last updated: 2026-07-03

Introduction
These Terms & Conditions ("Terms") govern your access to and use of the SMARTTT mobile and desktop application ("App"). By downloading, installing, or using the App you agree to be bound by these Terms. If you do not agree, do not use the App.

1. Definitions
- "App": the SMARTTT client applications and web build.
- "Service": backend services, APIs, and any hosted components that the App communicates with.
- "You" / "User": a student or authorized person using the App.

2. Scope of the Service
The App provides timetable visualization, portal-based unit synchronization, and related student features. The Service may change, be updated, or be discontinued at any time.

3. Accounts, Authentication & Security
- You must register for an account to access protected features. You are responsible for maintaining the confidentiality of your credentials and for all actions taken through your account.
- The App stores short-lived access tokens and refresh tokens locally to authenticate API requests. Protect your device and do not share credentials.

4. Portal Sync and Sensitive Data
- Portal Sync: when you use the Portal Sync feature you submit your university portal credentials for a single request. These credentials are transmitted to the Service to authenticate and fetch your registered unit list.
- The client does not persist portal passwords on disk; the backend is responsible for secure handling and immediate discard after scraping. You should only use official portal credentials and change your password if you suspect misuse.

5. Data Collection, Use, and Retention
- The App collects profile data (name, email, admission number, phone) and schedule-related data necessary to provide the Service.
- Collected data is used to build personalized timetables and is stored on the Service where retention and deletion obey the university's policies and applicable law.

6. Content Accuracy and Use
- Schedule data may originate from the university or from parsed portal data. The App strives for correctness but cannot guarantee completeness or timeliness. Always verify critical schedule changes with official university announcements.

7. Third-Party Services
- The App may rely on third-party libraries and services (e.g., authentication providers, analytics). Those services are governed by their own terms and privacy policies.

8. Prohibited Conduct
- You must not use the App to access or attempt to access accounts that are not your own, to interfere with the Service, or to conduct scraping or automated requests outside supported features.

9. Intellectual Property
- The App and its contents are the property of the App maintainers or licensors. You may not copy, reproduce, or distribute the App beyond permitted personal use.

10. Disclaimer of Warranties
- The App is provided "as is" and "as available" without warranties of any kind. To the fullest extent permitted by law, maintainers disclaim all warranties, including merchantability, fitness for a particular purpose, and non-infringement.

11. Limitation of Liability
- To the maximum extent permitted by law, neither the App maintainers nor contributors are liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.

12. Termination
- We may suspend or terminate access to the App for any user who violates these Terms or poses a security risk. You may delete your account according to the Service's account deletion flow where available.

13. Changes to Terms
- We may update these Terms. We will publish a revised date in the App. Continued use after updates constitutes acceptance of the updated Terms.

14. Governing Law
- These Terms are governed by the laws applicable where the university is located. Any disputes should be raised with university support or, if necessary, resolved in the appropriate courts.

15. Contact
For questions about these Terms or data handling, contact university support through the App's support option.

''';
