import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../domain/models/lecturer_dashboard_model.dart'; // Correct relative path
import '../widgets/lecturer_colors.dart';

class LecturerHomeTab extends ConsumerStatefulWidget {
  const LecturerHomeTab({super.key});

  @override
  ConsumerState<LecturerHomeTab> createState() => _LecturerHomeTabState();
}

class _LecturerHomeTabState extends ConsumerState<LecturerHomeTab> {
  String? selectedUnitIdForRoster;
  String? selectedUnitLabel;
  List<dynamic> rosterStudents = [];
  bool isLoadingRoster = false;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final dashboard = dashboardState.dashboard;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (dashboardState.isLoading && dashboard == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(lecturerDashboardProvider.notifier).fetchDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lecturer Portal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? LecturerColors.primary.withValues(alpha: 0.2) : LecturerColors.navyBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      dashboard?.currentTerm ?? 'Active Term',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LecturerColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatsStrip(dashboard?.summary, isDarkMode),
              const SizedBox(height: 24),
              Text(
                'My Timetable',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.grey[400] : Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildTimetableSection(dashboard, isDarkMode),
              if (selectedUnitIdForRoster != null) ...[
                const SizedBox(height: 24),
                _buildStudentRosterCard(isDarkMode),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsStrip(LecturerSummaryModel? summary, bool isDarkMode) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '${summary?.unitsCount ?? 0}', label: 'Units this term', isDarkMode: isDarkMode)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${summary?.weeklySessions ?? 0}', label: 'Weekly sessions', isDarkMode: isDarkMode)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${summary?.totalStudents ?? 0}', label: 'Total students', isDarkMode: isDarkMode)),
      ],
    );
  }

  Widget _buildTimetableSection(LecturerDashboardModel? dashboard, bool isDarkMode) {
    final dayNames = {'MON': 'Monday', 'TUE': 'Tuesday', 'WED': 'Wednesday', 'THU': 'Thursday', 'FRI': 'Friday', 'SAT': 'Saturday', 'SUN': 'Sunday'};
    final today = dashboard?.today ?? 'MON';
    final sessions = dashboard?.todaySessions ?? [];

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No classes scheduled for today.',
          style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isDarkMode ? LecturerColors.primary.withValues(alpha: 0.2) : LecturerColors.navyBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            dayNames[today] ?? today,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LecturerColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        // Lay sessions out in a grid rather than one full-width card per row,
        // so today's classes fill the available horizontal space instead of
        // leaving it empty next to a narrow stacked column.
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            const minCardWidth = 260.0;
            final columns = (constraints.maxWidth / minCardWidth).floor().clamp(1, 4);
            final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: sessions
                  .map((slot) => SizedBox(width: cardWidth, child: _buildSlotCard(slot, isDarkMode)))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlotCard(LecturerSessionModel slot, bool isDarkMode) {
    return InkWell(
      onTap: () => fetchStudentsForUnit(slot.unitId, '${slot.unitCode} — ${slot.unitName}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            right: BorderSide(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            bottom: BorderSide(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            left: const BorderSide(color: LecturerColors.primary, width: 4), // Correct left border styling
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.timeRange,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LecturerColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              slot.unitName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 3),
            Text(
              '${slot.unitCode} ${slot.room.isNotEmpty ? '· ${slot.room}' : ''} ${slot.program.isNotEmpty ? '· ${slot.program}' : ''}',
              style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchStudentsForUnit(String unitId, String unitLabel) async {
    setState(() {
      selectedUnitIdForRoster = unitId;
      selectedUnitLabel = unitLabel;
      isLoadingRoster = true;
    });

    try {
      final roster = await ref.read(lecturerRepositoryProvider).fetchRooms();
      setState(() {
        rosterStudents = [];
        isLoadingRoster = false;
      });
    } catch (_) {
      setState(() => isLoadingRoster = false);
    }
  }

  Widget _buildStudentRosterCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students — ${selectedUnitLabel ?? ""}',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.black87),
                onPressed: () => setState(() => selectedUnitIdForRoster = null),
              ),
            ],
          ),
          Divider(color: isDarkMode ? Colors.grey[800] : null),
          isLoadingRoster
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : rosterStudents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No enrolled students data loaded.',
                        style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rosterStudents.length,
                      itemBuilder: (context, idx) {
                        final s = rosterStudents[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            s['name'] ?? 'Student',
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(
                            s['email'] ?? '',
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                          ),
                          trailing: Chip(label: Text(s['university_id'] ?? 'ID')),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isDarkMode;

  const _StatCard({required this.value, required this.label, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LecturerColors.primary)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
