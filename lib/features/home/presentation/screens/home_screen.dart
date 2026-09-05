import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/timetable_card.dart';
import '../widgets/stats_card.dart';
import '../../../schedule/presentation/schedule_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../schedule/presentation/providers/timetable_provider.dart';
import '../../../schedule/domain/models/timetable_session_model.dart';
import '../../../notifications/providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch timetable sessions and current active term on startup
    Future.microtask(() {
      ref.read(timetableProvider.notifier).fetchMySchedule();
    });
  }

  List<Widget> get _screens => [
    _HomeTab(
      onViewSchedule: () => _onItemTapped(1),
    ),
    const ScheduleScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/portal-sync'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Sync'),
            ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.getTextSecondary(context),
        backgroundColor: AppTheme.getSurface(context),
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.calendar),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.profile_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final VoidCallback onViewSchedule;

  const _HomeTab({super.key, required this.onViewSchedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final timetableState = ref.watch(timetableProvider);
    final user = authState.user;

    final currentTime = DateTime.now();
    String greeting = 'Good morning';
    if (currentTime.hour >= 12 && currentTime.hour < 16) {
      greeting = 'Good afternoon';
    } else if (currentTime.hour >= 16) {
      greeting = 'Good evening';
    }

    final now = DateTime.now();
    final daysOfWeekMap = {
      DateTime.monday: 'MON',
      DateTime.tuesday: 'TUE',
      DateTime.wednesday: 'WED',
      DateTime.thursday: 'THU',
      DateTime.friday: 'FRI',
      DateTime.saturday: 'SAT',
      DateTime.sunday: 'SUN',
    };
    final currentDayStr = daysOfWeekMap[now.weekday];

    // Filter today's classes
    final classesToday = timetableState.sessions
        .where((s) => s.dayOfWeek.toUpperCase() == currentDayStr)
        .toList();

    // Sort today's classes by start time
    classesToday.sort((a, b) {
      try {
        final aStart = a.timeRange.split('-')[0].trim().split(':');
        final bStart = b.timeRange.split('-')[0].trim().split(':');
        final aMin = int.parse(aStart[0]) * 60 + int.parse(aStart[1]);
        final bMin = int.parse(bStart[0]) * 60 + int.parse(bStart[1]);
        return aMin.compareTo(bMin);
      } catch (_) {
        return 0;
      }
    });

    final nowTime = TimeOfDay.fromDateTime(now);
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;

    int completedCount = 0;
    int remainingCount = 0;
    for (final session in classesToday) {
      try {
        final parts = session.timeRange.split('-');
        if (parts.length == 2) {
          final endParts = parts[1].trim().split(':');
          final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          if (nowMinutes > endMinutes) {
            completedCount++;
          } else {
            remainingCount++;
          }
        }
      } catch (_) {
        remainingCount++;
      }
    }

    final cardColors = const [
  AppTheme.primary,
  AppTheme.secondary,
  AppTheme.accent,
  Color(0xFF1A6B3A),   // deep green — kept for variety, not brand
];

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.calendar_tick,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              user?.fullName ?? 'Student Name',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
         
Consumer(
  builder: (context, ref, _) {
    final unread = ref.watch(notificationProvider).unreadCount;
    return Stack(
      children: [
        IconButton(
          onPressed: () => context.pushNamed('alerts'),
          icon: Icon(
            Iconsax.notification,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
),
 
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(timetableProvider.notifier).fetchMySchedule();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timetableState.isFromCache) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline mode — displaying saved schedule',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Iconsax.book,
                      label: "Today's Classes",
                      value: '${classesToday.length}',
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      icon: Iconsax.box_tick,
                      label: 'Completed',
                      value: '$completedCount',
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      icon: Iconsax.clock,
                      label: 'Remaining',
                      value: '$remainingCount',
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ).animate().fadeIn().moveY(begin: 20),

              const SizedBox(height: 32),

              // Today's Schedule Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Schedule",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: onViewSchedule,
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms).moveY(begin: 20),

              const SizedBox(height: 16),

              // Timetable Cards
              _buildTodayScheduleSection(
                timetableState, 
                classesToday, 
                nowMinutes, 
                cardColors
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayScheduleSection(
    TimetableState state, 
    List<TimetableSessionModel> sessions, 
    int nowMinutes, 
    List<Color> cardColors
  ) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.danger, color: AppTheme.error, size: 36),
            const SizedBox(height: 12),
            Text(
              'Error loading schedule',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Iconsax.coffee, color: AppTheme.primary, size: 36),
              const SizedBox(height: 12),
              Text(
                'No classes scheduled for today',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Take a break or review your assignments!',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).moveY(begin: 20);
    }

    return Column(
      children: List.generate(sessions.length, (index) {
        final session = sessions[index];
        final cardColor = cardColors[index % cardColors.length];

        bool isCompleted = false;
        bool isCurrent = false;

        try {
          final parts = session.timeRange.split('-');
          if (parts.length == 2) {
            final startParts = parts[0].trim().split(':');
            final endParts = parts[1].trim().split(':');
            final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
            final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
            
            if (nowMinutes > endMinutes) {
              isCompleted = true;
            } else if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
              isCurrent = true;
            }
          }
        } catch (_) {}

        return TimetableCard(
          time: session.timeRange,
          subject: session.unitTitle,
          instructor: session.lecturerName ?? 'No lecturer assigned',
          location: session.roomCode ?? 'TBA',
          color: cardColor,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        );
      }),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20);
  }
}
