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
                  const Text(
                    'Lecturer Portal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: LecturerColors.navyBg,
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
              _buildStatsStrip(dashboard?.summary),
              const SizedBox(height: 24),
              const Text(
                'My Timetable',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildTimetableSection(dashboard?.timetable ?? {}),
              if (selectedUnitIdForRoster != null) ...[
                const SizedBox(height: 24),
                _buildStudentRosterCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsStrip(LecturerSummaryModel? summary) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '${summary?.unitsCount ?? 0}', label: 'Units this term')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${summary?.weeklySessions ?? 0}', label: 'Weekly sessions')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${summary?.totalStudents ?? 0}', label: 'Total students')),
      ],
    );
  }

  Widget _buildTimetableSection(Map<String, List<LecturerSessionModel>> timetable) {
    const dayOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final dayNames = {'MON': 'Monday', 'TUE': 'Tuesday', 'WED': 'Wednesday', 'THU': 'Thursday', 'FRI': 'Friday', 'SAT': 'Saturday'};

    final activeDays = dayOrder.where((d) => timetable.containsKey(d) && timetable[d]!.isNotEmpty).toList();

    if (activeDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Text('No classes assigned for this term yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activeDays.map((day) {
        final sessions = timetable[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: LecturerColors.navyBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                dayNames[day] ?? day,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LecturerColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            ...sessions.map((slot) => _buildSlotCard(slot)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSlotCard(LecturerSessionModel slot) {
    return InkWell(
      onTap: () => fetchStudentsForUnit(slot.unitId, '${slot.unitCode} — ${slot.unitName}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
            left: BorderSide(color: LecturerColors.primary, width: 4), // Correct left border styling
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              '${slot.unitCode} ${slot.room.isNotEmpty ? '· ${slot.room}' : ''} ${slot.program.isNotEmpty ? '· ${slot.program}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildStudentRosterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Students — ${selectedUnitLabel ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => selectedUnitIdForRoster = null),
              ),
            ],
          ),
          const Divider(),
          isLoadingRoster
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : rosterStudents.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Text('No enrolled students data loaded.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rosterStudents.length,
                      itemBuilder: (context, idx) {
                        final s = rosterStudents[idx];
                        return ListTile(
                          dense: true,
                          title: Text(s['name'] ?? 'Student'),
                          subtitle: Text(s['email'] ?? ''),
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

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LecturerColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
