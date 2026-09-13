import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../domain/models/lecturer_dashboard_model.dart';
import '../widgets/lecturer_colors.dart';

class LecturerHomeTab extends ConsumerWidget {
  const LecturerHomeTab({super.key});

  String _formatDate(DateTime now) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final user = authState.user;
    final dashboard = dashboardState.dashboard;

    final now = DateTime.now();
    String greeting = 'Good Morning';
    if (now.hour >= 12 && now.hour < 16) {
      greeting = 'Good Afternoon';
    } else if (now.hour >= 16) {
      greeting = 'Good Evening';
    }

    final firstName = (user?.fullName ?? 'Lecturer').split(' ').first;

    return RefreshIndicator(
      onRefresh: () => ref.read(lecturerDashboardProvider.notifier).fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              decoration: const BoxDecoration(
                color: LecturerColors.navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👋 $greeting,', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    firstName,
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(_formatDate(now), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),

            if (dashboardState.isLoading && dashboard == null)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: LecturerColors.navy)),
              )
            else if (dashboardState.error != null && dashboard == null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(dashboardState.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(lecturerDashboardProvider.notifier).fetchDashboard(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (dashboard != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: units / weekly sessions / total students ───
                    Row(
                      children: [
                        Expanded(child: _StatCard(value: '${dashboard.summary.unitsCount}', label: 'Units This Term', color: LecturerColors.navy)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: '${dashboard.summary.weeklySessions}', label: 'Weekly Sessions', color: LecturerColors.orange)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: '${dashboard.summary.totalStudents}', label: 'Total Students', color: LecturerColors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Row 2: completed / remaining today ────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _BigStatCard(
                            value: '${dashboard.summary.completedToday}',
                            label: 'Completed Today',
                            bg: LecturerColors.greenBg,
                            fg: LecturerColors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BigStatCard(
                            value: '${dashboard.summary.remainingToday}',
                            label: 'Remaining Today',
                            bg: LecturerColors.amberBg,
                            fg: LecturerColors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's Sessions", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(dashboard.today[0] + dashboard.today.substring(1).toLowerCase(),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (dashboard.todaySessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No sessions scheduled for today.', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...dashboard.todaySessions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SessionCard(session: s),
                          )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  const _BigStatCard({required this.value, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fg)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final LecturerSessionModel session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isNow = session.status == 'now';
    final bg = isNow ? LecturerColors.navyBg : LecturerColors.amberBg;
    final borderColor = isNow ? LecturerColors.navyBorder : LecturerColors.amber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.timeRange, style: TextStyle(color: borderColor, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(session.unitCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${session.room} · ${session.program} · ${session.studentCount} students',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (session.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNow ? LecturerColors.navyBorder : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                session.status == 'now' ? 'Now' : (session.status == 'completed' ? 'Done' : 'Upcoming'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isNow ? Colors.white : LecturerColors.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
