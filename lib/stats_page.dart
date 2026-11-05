import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'common.dart';
import 'widgets.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);

    final rate = s.totalCount == 0 ? 0.0 : s.doneCount / s.totalCount;
    final week = s.completedPerDay(7);
    final maxWeek = week.fold<int>(1, (m, v) => v > m ? v : m);
    final today = dayOnly(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          'Your progress',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: pal.text),
        ),
        const SizedBox(height: 12),

        // completion ring + streak
        SoftCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: rate),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: pal.soft,
                          valueColor: AlwaysStoppedAnimation(pal.primary),
                        ),
                      ),
                    ),
                    Text(
                      '${(rate * 100).round()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: pal.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completion rate',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: pal.text)),
                    const SizedBox(height: 4),
                    Text('${s.doneCount} of ${s.totalCount} tasks done',
                        style: TextStyle(color: pal.sub)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x22F2A33A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '🔥 ${s.streak} day streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE08A12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4 numbers
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.9,
          children: [
            _numberCard(pal, Icons.checklist_rounded, const Color(0xFF8A56EF), s.totalCount, 'Total'),
            _numberCard(pal, Icons.schedule_rounded, const Color(0xFFE5578A), s.pendingCount, 'Pending'),
            _numberCard(pal, Icons.check_circle_rounded, const Color(0xFF3DB67B), s.doneCount, 'Completed'),
            _numberCard(pal, Icons.hourglass_bottom_rounded, const Color(0xFFF2A33A), s.overdueCount, 'Overdue'),
          ],
        ),

        // weekly bars
        const SectionTitle('Completed this week'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          week[i] == 0 ? '' : '${week[i]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pal.sub,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: week[i] / maxWeek),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Container(
                            width: 22,
                            height: 6 + 84 * v,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [pal.primary, const Color(0xFFE59ADB)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('E').format(today.subtract(Duration(days: 6 - i))).substring(0, 2),
                          style: TextStyle(fontSize: 11, color: pal.sub),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // categories
        const SectionTitle('By category'),
        SoftCard(
          child: Column(
            children: [
              for (final c in kCategories) _categoryRow(s, pal, c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberCard(Pal pal, IconData icon, Color color, int value, String label) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: pal.text)),
                Text(label, style: TextStyle(fontSize: 12.5, color: pal.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(AppState s, Pal pal, CategoryInfo c) {
    final all = s.tasks.where((t) => t.category == c.key).toList();
    if (all.isEmpty) return const SizedBox.shrink();
    final done = all.where((t) => t.isDone).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(c.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(c.key,
                style: TextStyle(fontWeight: FontWeight.w600, color: pal.text)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: done / all.length,
                minHeight: 8,
                backgroundColor: pal.soft,
                valueColor: AlwaysStoppedAnimation(c.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/${all.length}', style: TextStyle(fontSize: 12, color: pal.sub)),
        ],
      ),
    );
  }
}
