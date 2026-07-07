import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en');
  }

  void setLocaleDirect(Locale locale) {
    state = locale;
  }

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'en';
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Swahili translations map.
/// Any string not found here falls back to the key itself (English).
const Map<String, Map<String, String>> appTranslations = {
  'en': {},
  'sw': {
    // Bottom nav
    'Home': 'Nyumbani',
    'Schedule': 'Ratiba',
    'Profile': 'Wasifu',
    // Profile screen
    'My Profile': 'Wasifu Wangu',
    'Edit Profile': 'Hariri Wasifu',
    'Academic Information': 'Taarifa za Kitaaluma',
    'Admission': 'Nambari ya Udahili',
    'Phone': 'Simu',
    'App Preferences': 'Mipangilio ya Programu',
    'Dark Mode': 'Hali ya Giza',
    'Push Notifications': 'Arifa za Push',
    'Language': 'Lugha',
    'Support & Feedback': 'Msaada na Maoni',
    'Contact University Support': 'Wasiliana na Msaada wa Chuo',
    'Report a Bug': 'Ripoti Hitilafu',
    'Terms & Conditions': 'Masharti na Vigezo',
    'Account': 'Akaunti',
    'Change Password': 'Badilisha Nywila',
    'Logout': 'Toka',
    // Schedule screen
    'Class Schedule': 'Ratiba ya Masomo',
    'No classes today': 'Hakuna masomo leo',
    'Enjoy your free day!': 'Furahia siku yako ya bure!',
    'Failed to load timetable': 'Imeshindwa kupakia ratiba',
    'Retry': 'Jaribu tena',
    'No lecturer assigned': 'Hakuna mwalimu aliyepewa',
    // Home screen
    "Today's Classes": 'Masomo ya Leo',
    'Completed': 'Imekamilika',
    'Remaining': 'Iliyobaki',
    "Today's Schedule": 'Ratiba ya Leo',
    'View All': 'Tazama Zote',
    'No classes scheduled for today': 'Hakuna masomo yaliyopangwa leo',
    'Take a break or review your assignments!': 'Pumzika au kagua kazi zako!',
    // Sync screen
    'Sync with Portal': 'Sawazisha na Lango',
    'Portal Admission Number': 'Nambari ya Udahili ya Lango',
    'Portal Password': 'Nywila ya Lango',
    'Sync Registered Units': 'Sawazisha Vitengo Vilivyosajiliwa',
    'Enter units manually instead': 'Ingiza vitengo kwa mkono badala yake',
    'Enter Units Manually': 'Ingiza Vitengo kwa Mkono',
    'Add another unit': 'Ongeza kitengo kingine',
    'Sync Units': 'Sawazisha Vitengo',
    // Auth screens
    'Sign In': 'Ingia',
    'Sign Up': 'Jisajili',
    'Email': 'Barua pepe',
    'Password': 'Nywila',
    'Full Name': 'Jina Kamili',
    'Admission Number': 'Nambari ya Udahili',
    'Forgot Password?': 'Umesahau Nywila?',
    'Already have an account?': 'Una akaunti tayari?',
    "Don't have an account?": 'Huna akaunti?',
  },
};

/// Helper to translate a string based on current locale.
/// Usage: context.tr('Home') or t(ref, 'Home')
extension TranslateExtension on BuildContext {
  String tr(String key) {
    // Get locale from inherited widget if available — falls back to English
    final locale = Localizations.localeOf(this).languageCode;
    return appTranslations[locale]?[key] ?? key;
  }
}
