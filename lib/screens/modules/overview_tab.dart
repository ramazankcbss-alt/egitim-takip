import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';
import 'homework_tab.dart';

/// ÖZET: tüm modüllerden kısa bir görünüm.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.student, required this.me});

  final Student student;
  final AppUser me;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late final LiveValue<List<Homework>> _hw =
      LiveValue(Db.homeworks(widget.student.id));
  late final LiveValue<List<ReadingLog>> _logs =
      LiveValue(Db.readingLogs(widget.student.id));
  late final LiveValue<List<TestBook>> _tbs =
      LiveValue(Db.testBooks(widget.student.id));
  late final LiveValue<List<TestResult>> _results =
      LiveValue(Db.testResults(widget.student.id));

  @override
  void dispose() {
    _hw.dispose();
    _logs.dispose();
    _tbs.dispose();
    _results.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final me = widget.me;
    return ListenableBuilder(
      listenable: Listenable.merge([_hw, _logs, _tbs, _results]),
      builder: (context, _) {
        if (_hw.loading) return const Loading();
        final homeworks = _hw.value ?? const <Homework>[];
        final t0 = today();
        final pending = homeworks.where((h) => !h.done).toList()
          ..sort((a, b) => (a.dueDate ?? DateTime(2100))
              .compareTo(b.dueDate ?? DateTime(2100)));
        final overdue = pending
            .where((h) => h.dueDate != null && h.dueDate!.isBefore(t0))
            .length;
        final toCheck = homeworks.where((h) => h.done && !h.checked).length;

        // Son 7 günün okuma grafiği
        final logs = _logs.value ?? const <ReadingLog>[];
        final days = List.generate(7, (i) => t0.subtract(Duration(days: 6 - i)));
        final dayPages = days
            .map((d) => logs
                .where((l) => l.date != null && DateUtils.isSameDay(l.date, d))
                .fold<int>(0, (a, l) => a + l.pages)
                .toDouble())
            .toList();
        final weekPages = dayPages.fold<double>(0, (a, b) => a + b).round();
        final dayLabels =
            days.map((d) => DateFormat.E('tr_TR').format(d)).toList();

        final tbs = _tbs.value ?? const <TestBook>[];
        final avgProgress = tbs.isEmpty
            ? 0.0
            : tbs.map((b) => b.progress).reduce((a, b) => a + b) / tbs.length;
        final solvedPages =
            tbs.fold<int>(0, (a, b) => a + b.solvedPages.length);

        final res = _results.value ?? const <TestResult>[];
        final lastNet = res.isEmpty ? '-' : res.first.net.toStringAsFixed(2);

        final isStudent = me.role == UserRole.student;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                isStudent
                    ? 'Merhaba ${s.name.split(' ').first}! 👋'
                    : '${s.name} • ${s.grade}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                StatCard(
                    icon: Icons.assignment_late_outlined,
                    label: overdue > 0
                        ? 'Bekleyen ödev ($overdue gecikmiş)'
                        : 'Bekleyen ödev',
                    value: '${pending.length}',
                    color: overdue > 0 ? Colors.red : null),
                StatCard(
                    icon: Icons.fact_check_outlined,
                    label: 'Kontrol bekleyen',
                    value: '$toCheck',
                    color: Colors.teal),
                StatCard(
                    icon: Icons.auto_stories,
                    label: 'Son 7 gün okunan',
                    value: '$weekPages sayfa',
                    color: Colors.orange),
                StatCard(
                    icon: Icons.library_books_outlined,
                    label: 'Test kitabı ilerleme',
                    value: '%${(avgProgress * 100).round()}',
                    color: Colors.indigo),
                StatCard(
                    icon: Icons.grid_view,
                    label: 'Çözülen test sayfası',
                    value: '$solvedPages',
                    color: Colors.purple),
                StatCard(
                    icon: Icons.trending_up,
                    label: 'Son deneme neti',
                    value: lastNet,
                    color: Colors.green),
              ],
            ),
            const SectionTitle('Son 7 gün okuma (sayfa)'),
            MiniBars(values: dayPages, labels: dayLabels),
            SectionTitle(isStudent ? 'Yapman gereken ödevler' : 'Bekleyen ödevler'),
            if (pending.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.celebration_outlined, color: Colors.green),
                  title: Text('Bekleyen ödev yok 🎉'),
                ),
              )
            else
              ...pending
                  .take(5)
                  .map((h) => HomeworkCard(student: s, me: me, hw: h)),
            if (pending.length > 5)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                    've ${pending.length - 5} ödev daha (Ödevler sekmesinde).',
                    textAlign: TextAlign.center),
              ),
          ],
        );
      },
    );
  }
}
