import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exam_models.dart';

/// Says whether exams are on, or that the timetable is a preview until the switch.
class ExamModeBanner extends StatelessWidget {
  final ExamTerm? term;
  final bool published;

  const ExamModeBanner({super.key, required this.term, required this.published});

  @override
  Widget build(BuildContext context) {
    final t = term;
    if (t == null || (!t.inExamMode && !published)) return const SizedBox.shrink();
    final String text;
    final Color color;
    if (t.inExamMode) {
      text = 'Exams are on. The teaching timetable is hidden until the exam period closes.';
      color = AppTheme.accent;
    } else {
      final at = t.examSwitchAt;
      text = at == null
          ? 'Preview: the exam timetable is out; classes carry on until exams begin.'
          : 'Preview: exams begin ${examDayLabel(at)} at ${_hhmm(at)}. Classes carry on until then.';
      color = AppTheme.secondary;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(t.inExamMode ? Iconsax.edit : Iconsax.calendar_1, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A day heading: "Monday 23 Nov".
class ExamDayHeader extends StatelessWidget {
  final DateTime day;

  const ExamDayHeader({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        examDayLabel(day),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// One paper (or practical, or duty): codes, title, time and where.
class ExamCard extends StatelessWidget {
  final String codes;
  final String title;
  final String timeRange;
  final String? where;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// A tag such as "Main invigilator" or "Practical".
  final String? tag;

  /// Extra lines under the card (e.g. rooms to collect scripts from).
  final List<String> notes;

  const ExamCard({
    super.key,
    required this.codes,
    required this.title,
    required this.timeRange,
    this.where,
    this.startsAt,
    this.endsAt,
    this.tag,
    this.notes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final done = endsAt != null && now.isAfter(endsAt!);
    final current = !done && startsAt != null && endsAt != null && !now.isBefore(startsAt!);
    final accent = current ? AppTheme.success : AppTheme.primary;
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(codes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (current) _chip('Now', AppTheme.success),
                if (tag != null) ...[const SizedBox(width: 6), _chip(tag!, AppTheme.secondary)],
              ],
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Iconsax.clock, size: 15, color: AppTheme.getTextSecondary(context)),
                const SizedBox(width: 6),
                Text(timeRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (where != null) ...[
                  const SizedBox(width: 16),
                  Icon(Iconsax.location, size: 15, color: AppTheme.getTextSecondary(context)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(where!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            for (final note in notes) ...[
              const SizedBox(height: 6),
              Text(note, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Shown when there's nothing to list, or the timetable couldn't load.
class ExamMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ExamMessage({super.key, required this.icon, required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 36),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

/// "Room LH1, Science Block" or just the room.
String examWhere(String? room, String? building) {
  if (room == null) return 'Room to be announced';
  return building == null ? room : '$room, $building';
}

String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
