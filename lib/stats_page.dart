import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'common.dart';
import 'widgets.dart';

/// Clean, compact progress screen: four ring cards, a mini week chart and
/// category bars. Everything fits on one phone screen without scrolling.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);

    final total = s.totalCount;
    double frac(int n) => total == 0 ? 0.0 : n / total;
    final week = s.completedPerDay(7);
    final maxWeek = week.fold<int>(1, (m, v) => v > m ? v : m);
    final today = dayOnly(DateTime.now());

    if (MediaQuery.of(context).size.width >= 900) {
      return _wide(s, pal, total, frac, week, maxWeek, today);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your progress',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: pal.text),
          ),
          Text(
            '${s.doneCount} of $total tasks done. Keep going 🌹',
            style: TextStyle(fontSize: 12.5, color: pal.sub),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            padding: EdgeInsets.zero,
            children: [
              _ringCard(pal, 'Completed', '${s.doneCount}', frac(s.doneCount), const Color(0xFF3DB67B)),
              _ringCard(pal, 'Pending', '${s.pendingCount}', frac(s.pendingCount), const Color(0xFFE5578A)),
              _ringCard(pal, 'Overdue', '${s.overdueCount}', frac(s.overdueCount), const Color(0xFFF2A33A)),
              _ringCard(pal, 'Day streak 🔥', '${s.streak}', (s.streak / 7).clamp(0.0, 1.0), const Color(0xFFC0609F)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Completed this week',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pal.text)),
          const SizedBox(height: 6),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${week[i]}',
                              style: TextStyle(fontSize: 10, color: pal.sub)),
                          const SizedBox(height: 2),
                          Container(
                            width: 16,
                            height: 4 + 42 * (week[i] / maxWeek),
                            decoration: BoxDecoration(
                              color: i == 6 ? pal.primary : pal.primary.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('E')
                                .format(today.subtract(Duration(days: 6 - i)))
                                .substring(0, 2),
                            style: TextStyle(fontSize: 10, color: pal.sub),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('By category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pal.text)),
          const SizedBox(height: 6),
          Expanded(
            child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final c in kCategories) _categoryRow(s, pal, c),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringCard(Pal pal, String label, String value, double fraction, Color color,
      {double ring = 52, double pad = 8, double font = 14, double labelSize = 12.5}) {
    return SoftCard(
      padding: EdgeInsets.all(pad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: ring,
            height: ring,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ring,
                  height: ring,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: ring / 8.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                Text(value,
                    style: TextStyle(fontSize: font, fontWeight: FontWeight.w800, color: pal.text)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                maxLines: 2,
                style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w600, color: pal.sub)),
          ),
        ],
      ),
    );
  }

  Widget _bars(Pal pal, List<int> week, int maxWeek, DateTime today,
      {double barWidth = 34, double maxBar = 150}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${week[i]}',
                    style: TextStyle(fontSize: 13, color: pal.sub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: barWidth,
                  height: 6 + maxBar * (week[i] / maxWeek),
                  decoration: BoxDecoration(
                    color: i == 6 ? pal.primary : pal.primary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('E').format(today.subtract(Duration(days: 6 - i))),
                  style: TextStyle(fontSize: 13, color: pal.sub),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Layout for wide screens (web): four cards in a row, the weekly chart
  /// and the categories side by side.
  Widget _wide(AppState s, Pal pal, int total, double Function(int) frac,
      List<int> week, int maxWeek, DateTime today) {
    Widget head(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(t,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
        );
    final cards = <Widget>[
      _ringCard(pal, 'Completed', '${s.doneCount}', frac(s.doneCount),
          const Color(0xFF3DB67B), ring: 78, pad: 18, font: 22, labelSize: 15),
      _ringCard(pal, 'Pending', '${s.pendingCount}', frac(s.pendingCount),
          const Color(0xFFE5578A), ring: 78, pad: 18, font: 22, labelSize: 15),
      _ringCard(pal, 'Overdue', '${s.overdueCount}', frac(s.overdueCount),
          const Color(0xFFF2A33A), ring: 78, pad: 18, font: 22, labelSize: 15),
      _ringCard(pal, 'Day streak 🔥', '${s.streak}', (s.streak / 7).clamp(0.0, 1.0),
          const Color(0xFFC0609F), ring: 78, pad: 18, font: 22, labelSize: 15),
    ];
    final cats = <Widget>[
      for (final c in kCategories) _categoryRow(s, pal, c),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your progress',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: pal.text)),
          const SizedBox(height: 4),
          Text('${s.doneCount} of $total tasks done. Keep going 🌹',
              style: TextStyle(fontSize: 15, color: pal.sub)),
          const SizedBox(height: 22),
          Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    head('Completed this week'),
                    SoftCard(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                      child: SizedBox(
                        height: 230,
                        child: _bars(pal, week, maxWeek, today),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    head('By category'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: s.tasks.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No tasks yet 🌹',
                                    style: TextStyle(color: pal.sub)),
                              ),
                            )
                          : Column(children: cats),
                    ),
                  ],
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(c.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(c.key,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: pal.text)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: done / all.length,
                minHeight: 7,
                backgroundColor: pal.soft,
                valueColor: AlwaysStoppedAnimation(c.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/${all.length}', style: TextStyle(fontSize: 11.5, color: pal.sub)),
        ],
      ),
    );
  }
}
