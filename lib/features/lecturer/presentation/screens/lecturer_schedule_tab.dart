import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../domain/models/lecturer_dashboard_model.dart';
import '../widgets/lecturer_colors.dart';

const _dayOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _dayLabels = {
  'MON': 'Mon', 'TUE': 'Tue', 'WED': 'Wed', 'THU': 'Thu',
  'FRI': 'Fri', 'SAT': 'Sat', 'SUN': 'Sun',
};
const _dayFullNames = {
  'MON': 'Monday', 'TUE': 'Tuesday', 'WED': 'Wednesday', 'THU': 'Thursday',
  'FRI': 'Friday', 'SAT': 'Saturday', 'SUN': 'Sunday',
};

class LecturerScheduleTab extends ConsumerStatefulWidget {
  const LecturerScheduleTab({super.key});

  @override
  ConsumerState<LecturerScheduleTab> createState() => _LecturerScheduleTabState();
}

class _LecturerScheduleTabState extends ConsumerState<LecturerScheduleTab> {
  String? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final dashboard = dashboardState.dashboard;

    if (dashboardState.isLoading && dashboard == null) {
      return const Center(child: CircularProgressIndicator(color: LecturerColors.navy));
    }
    if (dashboard == null) {
      return Center(
        child: TextButton(
          onPressed: () => ref.read(lecturerDashboardProvider.notifier).fetchDashboard(),
          child: const Text('Retry loading schedule'),
        ),
      );
    }

    final selectedDay = _selectedDay ?? dashboard.today;
    final sessionsForDay = dashboard.timetable[selectedDay] ?? [];

    return RefreshIndicator(
      onRefresh: () => ref.read(lecturerDashboardProvider.notifier).fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Allocated Units card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: LecturerColors.navy, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ALLOCATED UNITS',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(dashboard.currentTerm ?? '—',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dashboard.allocatedUnits
                        .map((code) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Text('${dashboard.allocatedUnits.length} units allocated',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Day selector ─────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dayOrder.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = _dayOrder[i];
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? LecturerColors.navy : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: isSelected ? LecturerColors.navy : Colors.grey.shade300),
                      ),
                      child: Text(
                        _dayLabels[day]!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dayFullNames[selectedDay]!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${sessionsForDay.length} session${sessionsForDay.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            if (sessionsForDay.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No sessions this day.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...sessionsForDay.asMap().entries.map((entry) {
                final colors = [LecturerColors.navyBorder, LecturerColors.amber, LecturerColors.green, LecturerColors.orange];
                final color = colors[entry.key % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScheduleSessionCard(session: entry.value, accentColor: color),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSessionCard extends StatelessWidget {
  final LecturerSessionModel session;
  final Color accentColor;
  const _ScheduleSessionCard({required this.session, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.timeRange, style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(session.unitCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text('${session.room} · ${session.program} · ${session.studentCount} students',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
