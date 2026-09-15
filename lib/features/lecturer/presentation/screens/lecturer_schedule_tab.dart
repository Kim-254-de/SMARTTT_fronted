import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../widgets/lecturer_colors.dart';

class LecturerScheduleTab extends ConsumerStatefulWidget {
  const LecturerScheduleTab({super.key});

  @override
  ConsumerState<LecturerScheduleTab> createState() => _LecturerScheduleTabState();
}

class _LecturerScheduleTabState extends ConsumerState<LecturerScheduleTab> {
  String selectedDay = 'MON';
  final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final timetable = dashboardState.dashboard?.timetable ?? {};
    final sessionsForDay = timetable[selectedDay] ?? [];
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Teaching Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDaySelector(isDarkMode),
          Expanded(
            child: sessionsForDay.isEmpty
                ? const Center(child: Text('No classes scheduled for this day.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: sessionsForDay.length,
                    itemBuilder: (context, index) {
                      final session = sessionsForDay[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildScheduleCard(
                          time: session.timeRange,
                          unitCode: session.unitCode,
                          unitName: session.unitName,
                          venue: session.room,
                          group: session.program,
                          studentCount: session.studentCount,
                          isDarkMode: isDarkMode,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDarkMode) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? LecturerColors.navy
                    : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? LecturerColors.navy
                      : (isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard({
    required String time,
    required String unitCode,
    required String unitName,
    required String venue,
    required String group,
    required int studentCount,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: LecturerColors.navy),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LecturerColors.navy),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LecturerColors.navyBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unitCode,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LecturerColors.navy),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unitName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDarkMode ? Colors.grey[800] : const Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(venue, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.group_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$studentCount Students • $group', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
