import 'package:flutter/material.dart';

import 'art.dart';
import 'common.dart';
import 'models.dart';

// ------------------------------------------------------------------
//  Rounded card used all over the app
// ------------------------------------------------------------------
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.border),
        boxShadow: pal.dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x148A56EF),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: pal.text,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
//  "Today's Tasks  3 / 6" card with progress bar
// ------------------------------------------------------------------
class TodayCard extends StatelessWidget {
  final int done;
  final int total;
  const TodayCard({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    final value = total == 0 ? 0.0 : done / total;
    final left = total - done;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pal.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x448A56EF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Tasks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Floating(
                child: Icon(Icons.star_rounded, color: Color(0xFFFFD86B), size: 30),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$done / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: const Color(0x44FFFFFF),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Nothing planned for today yet ✨'
                : left == 0
                    ? 'All done for today! 🎉'
                    : '$left ${left == 1 ? 'task' : 'tasks'} left - you can do it 💪',
            style: const TextStyle(color: Color(0xEEFFFFFF), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//  One task in a list
// ------------------------------------------------------------------
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onStar;
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onStar,
  });

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    final cat = catInfo(task.category);
    final overdue = task.isOverdue;
    final dateColor = overdue ? const Color(0xFFE5578A) : pal.sub;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 4, bottom: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone ? pal.primary : Colors.transparent,
                  border: Border.all(color: pal.primary, width: 2),
                ),
                child: task.isDone
                    ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: task.isDone ? pal.sub : pal.text,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (task.repeat != Repeat.none) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.repeat_rounded, size: 16, color: pal.primary),
                    ],
                    if (task.hasReminder && !task.isDone) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.notifications_active_rounded,
                          size: 15, color: pal.primary),
                    ],
                  ],
                ),
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: pal.sub),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 14, color: dateColor),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel(task.dueAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: dateColor,
                            fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    _chip('${cat.emoji} ${cat.key}', cat.color),
                    _chip(kPriorityNames[task.priority], priorityColor(task.priority)),
                  ],
                ),
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: task.progress,
                            minHeight: 6,
                            backgroundColor: pal.soft,
                            valueColor: AlwaysStoppedAnimation(pal.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${task.doneSubtasks}/${task.subtasks.length}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: pal.sub,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onStar,
            icon: Icon(
              task.isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
              color: task.isImportant ? const Color(0xFFFFC53D) : pal.sub,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//  Empty list message with the cat
// ------------------------------------------------------------------
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const CatWidget(size: 120),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pal.text),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.sub),
          ),
        ],
      ),
    );
  }
}
