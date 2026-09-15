import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../widgets/lecturer_colors.dart';
import 'lecturer_home_tab.dart';
import 'lecturer_schedule_tab.dart';
import 'lecturer_notification_tab.dart'; // 1. Import the notification broadcast tab
import 'lecturer_profile_tab.dart';

/// Route target for /lecturer/home — a single screen that owns bottom-nav
/// state and switches between the lecturer tabs, exactly like the
/// student HomeScreen switches Home/Schedule/Profile internally.
class LecturerShellScreen extends ConsumerStatefulWidget {
  const LecturerShellScreen({super.key});

  @override
  ConsumerState<LecturerShellScreen> createState() => _LecturerShellScreenState();
}

class _LecturerShellScreenState extends ConsumerState<LecturerShellScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(lecturerDashboardProvider.notifier).fetchDashboard());
  }

  // 2. Include LecturerNotificationTab in your tabs array
  final _tabs = const [
    LecturerHomeTab(),
    LecturerScheduleTab(),
    LecturerNotificationTab(),
    LecturerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: LecturerColors.navy,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Iconsax.calendar), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Iconsax.notification), label: 'Broadcast'), // 3. Add Broadcast item here
          BottomNavigationBarItem(icon: Icon(Iconsax.profile_circle), label: 'Profile'),
        ],
      ),
    );
  }
}
