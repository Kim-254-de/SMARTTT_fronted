import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart/features/exams/domain/exam_models.dart';
import 'package:smart/features/exams/presentation/lecturer_exams_tab.dart';
import 'package:smart/features/exams/presentation/providers/exam_provider.dart';
import 'package:smart/features/exams/presentation/student_exams_screen.dart';

/// SMARTTT's /exams/my/ and /exams/my-duties/ (apps/schedule/exam_views.py there).
const _term = {
  'id': '7',
  'academic_year': '2026/2027',
  'semester': 1,
  'start_date': '2026-09-07',
  'end_date': '2026-12-18',
  'is_current': true,
  'mode': 'exams',
  'exam_switch_at': '2026-11-20T06:00:00+03:00',
  'switched_at': '2026-11-20T06:00:00+03:00',
  'exam_closed_at': null,
};

Map<String, dynamic> _paper(String code, String date, String start, {String? room}) => {
      'key': code,
      'codes': code,
      'unit_codes': [code],
      'title': 'Paper $code',
      'date': date,
      'start_time': start,
      'end_time': '${(int.parse(start.split(':')[0]) + 2).toString().padLeft(2, '0')}:${start.split(':')[1]}',
      'room': room,
      'building': room == null ? null : 'Science Block',
    };

final _myExams = {
  'term': _term,
  'version': 2,
  'papers': [_paper('COSC 130', '2026-11-24', '08:30', room: 'LH2'), _paper('MATH 110', '2026-11-23', '11:30', room: 'LH1')],
  'practicals': [
    {'unit_codes': ['COSC 131'], 'title': 'Lab', 'date': '2026-11-25', 'start_time': '14:00', 'end_time': '16:00'},
  ],
};

final _myDuties = {
  'term': _term,
  'version': 2,
  'examiner': [_paper('COSC 130', '2026-11-24', '08:30')],
  'duties': [
    {..._paper('COSC 130', '2026-11-24', '08:30', room: 'LH1'), 'role': 'main', 'students': 120, 'collect_from': ['LH2', 'LH3']},
    {..._paper('MATH 110', '2026-11-23', '11:30', room: 'LH4'), 'role': 'extra', 'students': 40},
  ],
};

Widget _app(Widget child, List overrides) => ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(home: child),
    );

void main() {
  group('exam models', () {
    test('read a student\'s papers and practicals', () {
      final exams = StudentExams.fromJson(_myExams);
      expect(exams.published, isTrue);
      expect(exams.term!.inExamMode, isTrue);
      expect(exams.papers.first.room, 'LH2');
      expect(exams.papers.first.startsAt, DateTime(2026, 11, 24, 8, 30));
      expect(exams.practicals.single.codes, 'COSC 131');
    });

    test('read nothing published', () {
      final exams = StudentExams.fromJson({'term': null, 'version': null, 'papers': [], 'practicals': []});
      expect(exams.published, isFalse);
      expect(exams.term, isNull);
    });

    test('read duties, main with rooms to collect from', () {
      final duties = LecturerExams.fromJson(_myDuties).duties;
      expect(duties.first.isMain, isTrue);
      expect(duties.first.collectFrom, ['LH2', 'LH3']);
      expect(duties.last.collectFrom, isEmpty);
    });

    test('group by day, earliest first', () {
      final papers = StudentExams.fromJson(_myExams).papers;
      final days = byDay(papers, (p) => p.date);
      expect(days.keys.toList(), [DateTime(2026, 11, 23), DateTime(2026, 11, 24)]);
      expect(examDayLabel(DateTime(2026, 11, 23)), 'Monday 23 Nov');
    });
  });

  group('screens', () {
    testWidgets('a student sees each paper with their room', (tester) async {
      await tester.pumpWidget(_app(const StudentExamsScreen(), [
        studentExamsProvider.overrideWith((ref) async => StudentExams.fromJson(_myExams)),
      ]));
      await tester.pumpAndSettle();
      expect(find.textContaining('Exams are on'), findsOneWidget);
      expect(find.text('Monday 23 Nov'), findsOneWidget);
      expect(find.text('LH1, Science Block'), findsOneWidget);
      expect(find.text('Practicals'), findsOneWidget);
    });

    testWidgets('a student sees when nothing is published', (tester) async {
      await tester.pumpWidget(_app(const StudentExamsScreen(), [
        studentExamsProvider.overrideWith((ref) async => const StudentExams()),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('No exam timetable yet'), findsOneWidget);
    });

    testWidgets('a lecturer sees duties and the rooms to collect from', (tester) async {
      await tester.pumpWidget(_app(const LecturerExamsTab(), [
        lecturerExamsProvider.overrideWith((ref) async => LecturerExams.fromJson(_myDuties)),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Main invigilator'), findsOneWidget);
      expect(find.text('Collect the scripts from LH2, LH3'), findsOneWidget);
      expect(find.text('120 students in this room'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Examiner'), 200);
      expect(find.text('Papers you set'), findsOneWidget);
    });
  });
}
