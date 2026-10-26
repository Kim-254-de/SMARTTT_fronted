import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/exam_models.dart';
import 'providers/exam_provider.dart';
import 'widgets/exam_widgets.dart';

/// The lecturer's exams: invigilation duties by day (the main invigilator
/// collects the scripts from the other rooms), then the papers they set.
class LecturerExamsTab extends ConsumerWidget {
  const LecturerExamsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(lecturerExamsProvider);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        title: const Text('Exams', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(lecturerExamsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: exams.when(
            loading: () => const [
              Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator())),
            ],
            error: (e, _) => [
              ExamMessage(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load your exam duties',
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(lecturerExamsProvider),
              ),
            ],
            data: (data) => _content(data),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(LecturerExams data) {
    final children = <Widget>[ExamModeBanner(term: data.term, published: data.published)];
    if (!data.published) {
      return [
        ...children,
        const ExamMessage(
          icon: Iconsax.calendar_1,
          title: 'No exam timetable yet',
          message: 'Your invigilation duties and papers appear here once the exam timetable is published.',
        ),
      ];
    }
    children.add(_heading('Invigilation'));
    if (data.duties.isEmpty) {
      children.add(const ExamMessage(icon: Iconsax.tick_circle, title: 'No duties', message: 'You aren’t invigilating any paper.'));
    }
    for (final entry in byDay(data.duties, (d) => d.paper.date).entries) {
      children.add(ExamDayHeader(day: entry.key));
      for (final d in entry.value) {
        children.add(ExamCard(
          codes: d.paper.codes,
          title: d.paper.title,
          timeRange: d.paper.timeRange,
          where: d.paper.room ?? 'Room to be announced',
          startsAt: d.paper.startsAt,
          endsAt: d.paper.endsAt,
          tag: d.isMain ? 'Main invigilator' : 'Invigilator',
          notes: [
            '${d.students} student${d.students == 1 ? '' : 's'} in this room',
            if (d.isMain && d.collectFrom.isNotEmpty) 'Collect the scripts from ${d.collectFrom.join(', ')}',
          ],
        ));
      }
    }
    if (data.examiner.isNotEmpty) {
      children.add(_heading('Papers you set'));
      for (final p in data.examiner) {
        children.add(ExamCard(
          codes: p.codes,
          title: '${examDayLabel(p.date)}${p.title.isEmpty ? '' : ' · ${p.title}'}',
          timeRange: p.timeRange,
          startsAt: p.startsAt,
          endsAt: p.endsAt,
          tag: 'Examiner',
        ));
      }
    }
    return children;
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}
