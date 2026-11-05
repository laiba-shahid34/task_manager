import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'art.dart';
import 'common.dart';
import 'models.dart';
import 'widgets.dart';

/// Add a new task, or edit an existing one when [task] is given.
class TaskFormPage extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;
  const TaskFormPage({super.key, this.task, this.initialDate});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  final TextEditingController _subInput = TextEditingController();

  late String _category;
  late int _priority;
  late DateTime _due;
  late bool _reminder;
  late bool _important;
  late Repeat _repeat;
  late Set<int> _days;
  late List<Subtask> _subtasks;
  String? _titleError;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? 'Study';
    _priority = t?.priority ?? 1;
    _reminder = t?.hasReminder ?? true;
    _important = t?.isImportant ?? false;
    _repeat = t?.repeat ?? Repeat.none;
    _days = {...(t?.repeatDays ?? <int>[])};
    _subtasks = (t?.subtasks ?? <Subtask>[])
        .map((s) => Subtask(id: s.id, title: s.title, done: s.done))
        .toList();

    if (t != null) {
      _due = t.dueAt;
    } else {
      final base = widget.initialDate ?? DateTime.now();
      final soon = DateTime.now().add(const Duration(hours: 1));
      _due = DateTime(base.year, base.month, base.day, soon.hour, 0);
      if (_due.isBefore(DateTime.now()) && sameDay(base, DateTime.now())) {
        _due = DateTime(base.year, base.month, base.day, soon.hour, soon.minute);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _subInput.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _due = DateTime(d.year, d.month, d.day, _due.hour, _due.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (t != null) {
      setState(() => _due = DateTime(_due.year, _due.month, _due.day, t.hour, t.minute));
    }
  }

  void _addSubtask() {
    final text = _subInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(Subtask(title: text));
      _subInput.clear();
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a title');
      return;
    }
    final s = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // a text left in the sub-task box counts too
    final pending = _subInput.text.trim();
    if (pending.isNotEmpty) _subtasks.add(Subtask(title: pending));

    var days = _days.toList()..sort();
    if (_repeat == Repeat.weekly && days.isEmpty) days = [_due.weekday];

    final old = widget.task;
    final task = Task(
      id: old?.id,
      title: title,
      description: _desc.text.trim(),
      category: _category,
      priority: _priority,
      dueAt: _due,
      isDone: old?.isDone ?? false,
      hasReminder: _reminder,
      isImportant: _important,
      repeat: _repeat,
      repeatDays: _repeat == Repeat.weekly ? days : <int>[],
      completedAt: old?.completedAt,
      createdAt: old?.createdAt,
      subtasks: _subtasks,
    );

    await s.saveTask(task);

    final past = _reminder && _repeat == Repeat.none && _due.isBefore(DateTime.now());
    messenger.showSnackBar(SnackBar(
      content: Text(past
          ? 'Saved! The time has passed, so no reminder will ring.'
          : _editing
              ? 'Task updated 💜'
              : 'Task added ✨'),
    ));
    nav.pop();
  }

  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);

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
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_rounded, color: pal.text),
                    ),
                    Expanded(
                      child: Text(
                        _editing ? 'Edit Task ✏️' : 'Add New Task 💜',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: pal.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _jar(pal),
                    const SizedBox(height: 10),
                    _field(
                      pal,
                      icon: Icons.edit_note_rounded,
                      child: TextField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: pal.text, fontWeight: FontWeight.w600),
                        onChanged: (_) {
                          if (_titleError != null) setState(() => _titleError = null);
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Task title *',
                          hintText: 'e.g. Study Algorithms',
                          errorText: _titleError,
                        ),
                      ),
                    ),
                    _field(
                      pal,
                      icon: Icons.notes_rounded,
                      child: TextField(
                        controller: _desc,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: pal.text),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Description (optional)',
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _pickerCard(
                            pal,
                            icon: Icons.calendar_month_rounded,
                            label: 'Due date',
                            value: DateFormat('EEE, d MMM').format(_due),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _pickerCard(
                            pal,
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: timeLabel(_due),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SectionTitle('Priority'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Low')),
                          ButtonSegment(value: 1, label: Text('Medium')),
                          ButtonSegment(value: 2, label: Text('High')),
                        ],
                        selected: {_priority},
                        onSelectionChanged: (v) => setState(() => _priority = v.first),
                      ),
                    ),
                    const SectionTitle('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in kCategories)
                          ChoiceChip(
                            label: Text('${c.emoji} ${c.key}'),
                            selected: _category == c.key,
                            showCheckmark: false,
                            selectedColor: c.color.withValues(alpha: 0.28),
                            backgroundColor: pal.card,
                            side: BorderSide(color: pal.border),
                            labelStyle: TextStyle(color: pal.text, fontWeight: FontWeight.w600),
                            onSelected: (_) => setState(() => _category = c.key),
                          ),
                      ],
                    ),
                    const SectionTitle('Repeat'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<Repeat>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: Repeat.none, label: Text('Never')),
                          ButtonSegment(value: Repeat.daily, label: Text('Daily')),
                          ButtonSegment(value: Repeat.weekly, label: Text('Weekly')),
                        ],
                        selected: {_repeat},
                        onSelectionChanged: (v) => setState(() => _repeat = v.first),
                      ),
                    ),
                    if (_repeat == Repeat.weekly) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 7; i++)
                            _dayCircle(pal, i + 1, kWeekdayLetter[i]),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _reminder,
                            onChanged: (v) => setState(() => _reminder = v),
                            secondary: Icon(Icons.notifications_active_rounded, color: pal.primary),
                            title: Text('Add reminder',
                                style: TextStyle(color: pal.text, fontWeight: FontWeight.w600)),
                            subtitle: Text('Notification at the chosen time',
                                style: TextStyle(color: pal.sub, fontSize: 12)),
                          ),
                          SwitchListTile(
                            value: _important,
                            onChanged: (v) => setState(() => _important = v),
                            secondary: const Icon(Icons.star_rounded, color: Color(0xFFFFC53D)),
                            title: Text('Mark as important',
                                style: TextStyle(color: pal.text, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SectionTitle('Sub-tasks'),
                    SoftCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < _subtasks.length; i++)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.subdirectory_arrow_right_rounded, color: pal.sub),
                              title: Text(_subtasks[i].title, style: TextStyle(color: pal.text)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: pal.sub,
                                onPressed: () => setState(() => _subtasks.removeAt(i)),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subInput,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _addSubtask(),
                                  style: TextStyle(color: pal.text),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Add a step...',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _addSubtask,
                                icon: Icon(Icons.add_circle_rounded, color: pal.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: pal.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          _editing ? 'Save Changes ✨' : 'Add Task ✨',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
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

  // ---------------- small pieces ----------------
  Widget _jar(Pal pal) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: pal.soft,
              border: Border.all(color: pal.primary.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: pal.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
          const Positioned(
            top: 4,
            child: Text('🎀', style: TextStyle(fontSize: 22)),
          ),
          const Floating(child: Text('⭐', style: TextStyle(fontSize: 42))),
          const Positioned(left: 80, top: 20, child: Floating(child: Text('🦋', style: TextStyle(fontSize: 22)))),
          const Positioned(right: 80, bottom: 14, child: Floating(child: Text('✨', style: TextStyle(fontSize: 20)))),
        ],
      ),
    );
  }

  Widget _field(Pal pal, {required IconData icon, required Widget child}) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 2, 12, 2),
      child: Row(
        children: [
          Icon(icon, color: pal.primary),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _pickerCard(
    Pal pal, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: pal.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: pal.sub)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: pal.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCircle(Pal pal, int weekday, String letter) {
    final on = _days.contains(weekday);
    return GestureDetector(
      onTap: () => setState(() {
        if (on) {
          _days.remove(weekday);
        } else {
          _days.add(weekday);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? pal.primary : pal.card,
          border: Border.all(color: on ? pal.primary : pal.border),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : pal.text,
          ),
        ),
      ),
    );
  }
}
