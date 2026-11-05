import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'common.dart';
import 'models.dart';
import 'task_detail_page.dart';
import 'widgets.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);
    final today = dayOnly(DateTime.now());
    final selected = s.selectedDay;

    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1; // Mon first

    final dayTasks = s.tasksOn(selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          'Calendar',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: pal.text),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shift(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: pal.primary),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: pal.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shift(1),
                    icon: Icon(Icons.chevron_right_rounded, color: pal.primary),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final d in kWeekdayShort)
                    Expanded(
                      child: Center(
                        child: Text(
                          d.substring(0, 2),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pal.sub,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= daysInMonth; d++)
                    _dayCell(s, pal, DateTime(_month.year, _month.month, d), today, selected),
                ],
              ),
            ],
          ),
        ),
        SectionTitle(
          sameDay(selected, today)
              ? 'Today'
              : DateFormat('EEEE, d MMMM').format(selected),
        ),
        if (dayTasks.isEmpty)
          SoftCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No tasks on this day 🌙\nTap + to add one',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.sub),
                ),
              ),
            ),
          )
        else
          for (final Task t in dayTasks)
            TaskTile(
              task: t,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskDetailPage(taskId: t.id!),
                ),
              ),
              onToggle: () => s.toggleDone(t),
              onStar: () => s.toggleImportant(t),
            ),
      ],
    );
  }

  Widget _dayCell(AppState s, Pal pal, DateTime date, DateTime today, DateTime selected) {
    final isToday = sameDay(date, today);
    final isSelected = sameDay(date, selected);
    final list = s.tasksOn(date);

    Color? dot;
    if (list.isNotEmpty) {
      if (list.any((t) => t.isOverdue)) {
        dot = const Color(0xFFE5578A);
      } else if (list.every((t) => t.isDone)) {
        dot = const Color(0xFF3DB67B);
      } else {
        dot = pal.primary;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => s.selectDay(date),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? pal.primary : Colors.transparent,
          border: isToday && !isSelected
              ? Border.all(color: pal.primary, width: 1.6)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : pal.text,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot == null
                    ? Colors.transparent
                    : (isSelected ? Colors.white : dot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
