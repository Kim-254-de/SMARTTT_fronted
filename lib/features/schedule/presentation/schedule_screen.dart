import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/timetable_session_model.dart';
import 'providers/timetable_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_message.dart';
import '../../../widgets/theme_cycle_button.dart';

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
  ];

  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Classes run Monday to Friday; on a weekend open on Monday.
    final weekday = DateTime.now().weekday;
    _selectedDayIndex = weekday <= DateTime.friday ? weekday - 1 : 0;
    Future.microtask(() {
      ref.read(timetableProvider.notifier).fetchMySchedule();
    });
  }

  // iCalendar
  //
  // calendar.ics can't take our normal JWT header (calendar apps poll it
  // directly, with no Authorization header) - it authenticates via a signed
  // token in the query string instead, minted by calendar-token/. Launching
  // the bare .ics URL without one always got "Missing token" from the
  // backend; feed_url below is the backend's own absolute URL with that
  // token already attached, so this also stays correct across environments
  // instead of a hardcoded production host.
  Future<void> subscribeCalendar() async {
    try {
      final response = await apiClient.dio.get('schedule/calendar-token/');
      final feedUrl = response.data['feed_url'] as String;
      await launchUrl(Uri.parse(feedUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e, fallbackMessage: 'Could not open the calendar subscription. Please try again.')), backgroundColor: AppTheme.error),
      );
    }
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
        actions: [const ThemeCycleButton(),
            
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Add to Calendar',
            onPressed: subscribeCalendar,
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Your Class Groups',
            onPressed: () => context.push('/select-groups'),
          ),
        ],
       ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(timetableProvider.notifier).fetchMySchedule(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Summary(termLabel: state.termLabel, unitCount: state.unitCount, conflictCount: state.conflicts.length),
            const SizedBox(height: 16),
            if (state.unitsNeedingGroupSelection.isNotEmpty) ...[
              _GroupSelectionBanner(count: state.unitsNeedingGroupSelection.length),
              const SizedBox(height: 12),
            ],
            if (state.isFromCache) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.getWarningSoft(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.offline_bolt_outlined, size: 18, color: AppTheme.getWarning(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline: showing your saved timetable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getWarning(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Five equal day buttons in one row, so they fit a small phone.
            Row(
              children: List.generate(_days.length, (index) {
                final day = _days[index];
                final isSelected = index == _selectedDayIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == _days.length - 1 ? 0 : 6),
                    child: Material(
                      color: isSelected ? AppTheme.primary : AppTheme.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? null : Border.all(color: AppTheme.getBorder(context)),
                          ),
                          child: Text(
                            day.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
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
            else if (state.error != null && state.sessions.isEmpty) ...[
              () {
                final isAuth = state.error!.toLowerCase().contains('session has expired');
                return _EmptyState(
                  icon: isAuth ? Icons.lock_clock_outlined : Icons.error_outline,
                  title: isAuth ? 'Session Expired' : 'Failed to load timetable',
                  message: isAuth
                      ? 'Your session has expired. Please log in again to view your schedule.'
                      : state.error!,
                  actionLabel: isAuth ? 'Log In' : 'Retry',
                  onAction: () {
                    if (isAuth) {
                      context.go('/login');
                    } else {
                      ref.read(timetableProvider.notifier).fetchMySchedule();
                    }
                  },
                );
              }(),
            ]
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

class _GroupSelectionBanner extends StatelessWidget {
  const _GroupSelectionBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/select-groups'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.getBrandSoft(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_outlined, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1
                    ? '1 unit needs your class group — tap to pick it'
                    : '$count units need your class group — tap to pick them',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.primary),
          ],
        ),
      ),
    );
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${session.startTime} - ${session.endTime}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              const SizedBox(width: 8),
              // The code can be long ("BITE 131/COSC 130"): it wraps rather than squeezing the title.
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getBrandSoft(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      session.unitCode,
                      softWrap: true,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.unitTitle,
            softWrap: true,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
          ),
          const SizedBox(height: 8),
          _Detail(
            icon: Icons.person_outline,
            text: session.lecturerName?.isNotEmpty == true ? session.lecturerName! : 'No lecturer assigned',
          ),
          const SizedBox(height: 4),
          _Detail(
            icon: Icons.location_on_outlined,
            text: session.roomCode?.isNotEmpty == true ? session.roomCode! : 'Room to be announced',
          ),
        ],
      ),
    );
  }
}

/// An icon and a line of text that wraps (never cut off) on a narrow phone.
class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppTheme.getTextSecondary(context)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, softWrap: true, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.termLabel, required this.unitCount, required this.conflictCount});

  final String? termLabel;
  final int unitCount;
  final int conflictCount;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context));
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (termLabel != null)
          Text(termLabel!, softWrap: true, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.getTextPrimary(context))),
        Text(unitCount == 1 ? '1 unit' : '$unitCount units', style: muted),
        if (conflictCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(
              conflictCount == 1 ? '1 clash' : '$conflictCount clashes',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.error),
            ),
          ),
      ],
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
