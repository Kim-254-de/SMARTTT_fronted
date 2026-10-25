import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/exam_models.dart';
import 'providers/exam_provider.dart';
import 'widgets/exam_widgets.dart';

/// The student's exam timetable: each paper with the room they sit it in,
/// by day, then the practicals. Before the switch it's a preview.
class StudentExamsScreen extends ConsumerWidget {
  const StudentExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(studentExamsProvider);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        title: const Text('Exams', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentExamsProvider.future),
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
                title: 'Unable to load your exams',
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(studentExamsProvider),
              ),
            ],
            data: (data) => _content(data),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(StudentExams data) {
    final children = <Widget>[ExamModeBanner(term: data.term, published: data.published)];
    if (!data.published) {
      return [
        ...children,
        const ExamMessage(
          icon: Iconsax.calendar_1,
          title: 'No exam timetable yet',
          message: 'Your papers and rooms appear here once the exam timetable is published.',
        ),
      ];
    }
    if (data.papers.isEmpty && data.practicals.isEmpty) {
      return [
        ...children,
        const ExamMessage(
          icon: Iconsax.calendar_1,
          title: 'No papers for you',
          message: 'None of the published papers lists your class. If that looks wrong, check your programme and year in your profile.',
        ),
      ];
    }
    for (final entry in byDay(data.papers, (p) => p.date).entries) {
      children.add(ExamDayHeader(day: entry.key));
      for (final p in entry.value) {
        children.add(ExamCard(
          codes: p.codes,
          title: p.title,
          timeRange: p.timeRange,
          where: examWhere(p.room, p.building),
          startsAt: p.startsAt,
          endsAt: p.endsAt,
        ));
      }
    }
    if (data.practicals.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 20, bottom: 4),
        child: Text('Practicals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ));
      for (final p in data.practicals) {
        children.add(ExamCard(
          codes: p.codes,
          title: '${examDayLabel(p.date)}${p.title.isEmpty ? '' : ' · ${p.title}'}',
          timeRange: p.timeRange,
          tag: 'Practical',
        ));
      }
    }
    return children;
  }
}
