import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/network/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/schedule_error_card.dart';
import '../data/exams_repository.dart';
import 'exams_provider.dart';

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

String _dayLabel(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

/// The student's exam timetable: only the papers and practicals of the units
/// they synced, by date, each with its time and their room.
class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(myExamsProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Exam Timetable'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myExamsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: exams.when(
            loading: () => const [
              Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator())),
            ],
            error: (e, _) => [
              ScheduleErrorCard(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(myExamsProvider),
              ),
            ],
            data: (result) => _content(context, result),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, MyExamsResult result) {
    final header = <Widget>[
      if (result.termLabel != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            result.version != null ? '${result.termLabel} · version ${result.version}' : result.termLabel!,
            style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
          ),
        ),
      if (result.isFromCache) ...[
        _Banner(
          icon: Icons.offline_bolt_outlined,
          color: Colors.amber.shade900,
          background: Colors.amber.shade50,
          border: Colors.amber.shade300,
          text: 'Offline: showing your exams as last loaded.',
        ),
        const SizedBox(height: 12),
      ],
    ];

    if (result.items.isEmpty) {
      return [...header, _EmptyState(message: result.message ?? 'No exams to show yet.')];
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final byDay = <DateTime, List<ExamItem>>{};
    for (final item in result.items) {
      byDay.putIfAbsent(item.date, () => []).add(item);
    }
    return [
      ...header,
      for (final entry in byDay.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            _dayLabel(entry.key),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: entry.key == todayDate ? AppTheme.primary : AppTheme.getTextSecondary(context),
            ),
          ),
        ),
        for (final item in entry.value) _ExamCard(item: item, isPast: entry.key.isBefore(todayDate)),
      ],
    ];
  }
}

class _ExamCard extends StatelessWidget {
  final ExamItem item;
  final bool isPast;

  const _ExamCard({required this.item, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final accent = item.isPractical ? AppTheme.accent : AppTheme.primary;
    final rooms = item.rooms.map((r) => r.parts > 1 ? '${r.room} (part ${r.part} of ${r.parts})' : r.room).toList();

    return Opacity(
      opacity: isPast ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: accent, width: 4),
            top: BorderSide(color: AppTheme.getBorder(context)),
            right: BorderSide(color: AppTheme.getBorder(context)),
            bottom: BorderSide(color: AppTheme.getBorder(context)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.codesLabel,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextPrimary(context)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isPractical ? 'PRACTICAL' : (item.sitting == 'odel' ? 'WRITTEN · ODEL' : 'WRITTEN'),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                  ),
                ),
              ],
            ),
            if (item.title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.title, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
            ],
            const SizedBox(height: 12),
            _Line(icon: Iconsax.clock, text: '${item.startTime} – ${item.endTime}'),
            if (!item.isPractical) ...[
              const SizedBox(height: 6),
              _Line(
                icon: Iconsax.location,
                text: rooms.isEmpty ? 'Room to be announced' : rooms.join(', '),
                bold: item.roomConfirmed,
              ),
              if (!item.roomConfirmed && rooms.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    rooms.length > 1
                        ? 'Your room isn\'t certain: check the notice board for which of these is yours.'
                        : 'Check the notice board to confirm your room.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ] else if (item.department.isNotEmpty) ...[
              const SizedBox(height: 6),
              _Line(icon: Iconsax.building, text: 'Set by ${item.department}: venue from your department'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;

  const _Line({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.getTextSecondary(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final String text;

  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Iconsax.task_square, size: 56, color: AppTheme.getTextSecondary(context)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Only exams for the units you synced are shown.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/student-preferences'),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Sync my units'),
          ),
        ],
      ),
    );
  }
}
