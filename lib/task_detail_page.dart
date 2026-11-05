import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'common.dart';
import 'models.dart';
import 'task_form_page.dart';
import 'widgets.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TextEditingController _step = TextEditingController();

  @override
  void dispose() {
    _step.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(AppState s, Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete task? 🗑️'),
        content: Text('"${t.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    nav.pop();
    final removed = await s.deleteTask(t);
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${removed.title}" deleted'),
        action: SnackBarAction(label: 'UNDO', onPressed: () => s.restoreTask(removed)),
      ),
    );
  }

  Future<void> _addStep(AppState s, Task t) async {
    final text = _step.text.trim();
    if (text.isEmpty) return;
    _step.clear();
    await s.addSubtask(t, text);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);
    final t = s.byId(widget.taskId);

    if (t == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    final cat = catInfo(t.category);
    final pc = priorityColor(t.priority);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: pal.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_rounded, color: pal.text),
                    ),
                    Expanded(
                      child: Text(
                        'Task details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: pal.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => s.toggleImportant(t),
                      icon: Icon(
                        t.isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: t.isImportant ? const Color(0xFFFFC53D) : pal.sub,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // main card
                    SoftCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: t.isDone ? pal.sub : pal.text,
                              decoration: t.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (t.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(t.description, style: TextStyle(color: pal.sub, height: 1.35)),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill('${cat.emoji} ${t.category}', cat.color),
                              _pill('${kPriorityNames[t.priority]} priority', pc),
                              _pill(
                                t.isDone
                                    ? 'Completed'
                                    : t.isOverdue
                                        ? 'Overdue'
                                        : 'Pending',
                                t.isDone
                                    ? const Color(0xFF3DB67B)
                                    : t.isOverdue
                                        ? const Color(0xFFE5578A)
                                        : pal.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _infoRow(pal, Icons.calendar_month_rounded,
                              DateFormat('EEEE, d MMMM yyyy').format(t.dueAt)),
                          _infoRow(pal, Icons.access_time_rounded, timeLabel(t.dueAt)),
                          _infoRow(pal, Icons.repeat_rounded, t.repeatLabel),
                          _infoRow(
                            pal,
                            t.hasReminder
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            t.hasReminder ? 'Reminder on' : 'No reminder',
                            trailing: Switch(
                              value: t.hasReminder,
                              onChanged: (_) => s.toggleReminder(t),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // sub-tasks
                    const SectionTitle('Progress'),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: t.progress),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (context, v, _) => LinearProgressIndicator(
                                      value: v,
                                      minHeight: 10,
                                      backgroundColor: pal.soft,
                                      valueColor: AlwaysStoppedAnimation(pal.primary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(t.progress * 100).round()}%',
                                style: TextStyle(fontWeight: FontWeight.w800, color: pal.text),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (final sub in t.subtasks)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: sub.done,
                              onChanged: (_) => s.toggleSubtask(t, sub),
                              title: Text(
                                sub.title,
                                style: TextStyle(
                                  color: sub.done ? pal.sub : pal.text,
                                  decoration: sub.done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: pal.sub,
                                onPressed: () => s.removeSubtask(t, sub),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _step,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _addStep(s, t),
                                  style: TextStyle(color: pal.text),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Add a sub-task...',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _addStep(s, t),
                                icon: Icon(Icons.add_circle_rounded, color: pal.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // actions
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => s.toggleDone(t),
                        style: FilledButton.styleFrom(
                          backgroundColor: t.isDone ? pal.sub : const Color(0xFF3DB67B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        icon: Icon(t.isDone ? Icons.undo_rounded : Icons.check_circle_rounded),
                        label: Text(
                          t.isDone ? 'Mark as not done' : 'Mark as completed',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskFormPage(task: t.clone()),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(s, t),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE5578A),
                            ),
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12.5),
        ),
      );

  Widget _infoRow(Pal pal, IconData icon, String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: pal.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: pal.text))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
