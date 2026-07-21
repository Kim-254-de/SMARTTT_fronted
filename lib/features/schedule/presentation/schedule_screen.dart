import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/timetable_session_model.dart';
import 'providers/timetable_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  static const List<_DayItem> _days = [
    _DayItem(label: 'Mon', keyName: 'MON'),
    _DayItem(label: 'Tue', keyName: 'TUE'),
    _DayItem(label: 'Wed', keyName: 'WED'),
    _DayItem(label: 'Thu', keyName: 'THU'),
    _DayItem(label: 'Fri', keyName: 'FRI'),
    _DayItem(label: 'Sat', keyName: 'SAT'),
    _DayItem(label: 'Sun', keyName: 'SUN'),
  ];

  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday - 1;
    Future.microtask(() {
      ref.read(timetableProvider.notifier).fetchMySchedule();
    });
  }

  // iCalendar

 Future<void> subscribeCalendar() async {
  final uri = Uri.parse(
    'https://smarttt-backend-n44z.onrender.com/api/v1/schedule/calendar.ics',
  );

  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);
    final selectedDay = _days[_selectedDayIndex];
    final sessions = _sessionsForDay(state.sessions, selectedDay.keyName);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Class Schedule'),
        centerTitle: true,
       ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(timetableProvider.notifier).fetchMySchedule(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: subscribeCalendar,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Add to Calendar'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (state.termLabel != null) ...[
              _InfoCard(
                title: 'Current Term',
                value: state.termLabel!,
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Units',
                    value: '${state.unitCount}',
                    icon: Icons.book_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Conflicts',
                    value: '${state.conflicts.length}',
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_days.length, (index) {
                final day = _days[index];
                final isSelected = index == _selectedDayIndex;
                return ChoiceChip(
                  label: Text(day.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDayIndex = index),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            if (state.isLoading && state.sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.sessions.isEmpty)
              _EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load timetable',
                message: state.error!,
                actionLabel: 'Retry',
                onAction: () => ref.read(timetableProvider.notifier).fetchMySchedule(),
              )
            else if (sessions.isEmpty)
              const _EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No classes for this day',
                message: 'There are no sessions scheduled for the selected day.',
              )
            else
              Column(
                children: sessions
                    .map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCard(session: session),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<TimetableSessionModel> _sessionsForDay(List<TimetableSessionModel> sessions, String keyName) {
    final daySessions = sessions.where((s) => s.dayOfWeek.toUpperCase() == keyName).toList();
    daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return daySessions;
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final TimetableSessionModel session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.unitTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  session.unitCode,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${session.startTime} - ${session.endTime}',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.lecturerName?.isNotEmpty == true ? session.lecturerName! : 'No lecturer assigned',
            style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            session.roomCode?.isNotEmpty == true ? session.roomCode! : 'Room TBA',
            style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.getTextSecondary(context)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DayItem {
  const _DayItem({required this.label, required this.keyName});

  final String label;
  final String keyName;
}
