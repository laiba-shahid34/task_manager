import 'common.dart';

enum Repeat { none, daily, weekly }

class Subtask {
  int? id;
  String title;
  bool done;
  Subtask({this.id, required this.title, this.done = false});
}

class Task {
  int? id;
  String title;
  String description;
  String category;
  int priority; // 0 low, 1 medium, 2 high
  DateTime dueAt;
  bool isDone;
  bool hasReminder;
  bool isImportant;
  Repeat repeat;
  List<int> repeatDays; // DateTime.weekday values: 1 = Mon ... 7 = Sun
  DateTime? completedAt;
  DateTime createdAt;
  List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.category = 'Study',
    this.priority = 1,
    required this.dueAt,
    this.isDone = false,
    this.hasReminder = true,
    this.isImportant = false,
    this.repeat = Repeat.none,
    List<int>? repeatDays,
    this.completedAt,
    DateTime? createdAt,
    List<Subtask>? subtasks,
  })  : repeatDays = repeatDays ?? <int>[],
        createdAt = createdAt ?? DateTime.now(),
        subtasks = subtasks ?? <Subtask>[];

  bool get isOverdue => !isDone && dueAt.isBefore(DateTime.now());

  int get doneSubtasks => subtasks.where((s) => s.done).length;

  double get progress {
    if (subtasks.isEmpty) return isDone ? 1.0 : 0.0;
    return doneSubtasks / subtasks.length;
  }

  String get repeatLabel {
    switch (repeat) {
      case Repeat.none:
        return 'Does not repeat';
      case Repeat.daily:
        return 'Every day';
      case Repeat.weekly:
        final days = [...repeatDays]..sort();
        return 'Every ${days.map((d) => kWeekdayShort[d - 1]).join(', ')}';
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'isDone': isDone ? 1 : 0,
        'hasReminder': hasReminder ? 1 : 0,
        'isImportant': isImportant ? 1 : 0,
        'repeatType': repeat.index,
        'repeatDays': repeatDays.join(','),
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> m) {
    final daysText = (m['repeatDays'] as String?) ?? '';
    final completed = m['completedAt'] as int?;
    return Task(
      id: m['id'] as int,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      category: (m['category'] as String?) ?? 'Other',
      priority: m['priority'] as int,
      dueAt: DateTime.fromMillisecondsSinceEpoch(m['dueAt'] as int),
      isDone: (m['isDone'] as int) == 1,
      hasReminder: (m['hasReminder'] as int) == 1,
      isImportant: (m['isImportant'] as int) == 1,
      repeat: Repeat.values[m['repeatType'] as int],
      repeatDays: daysText.isEmpty
          ? <int>[]
          : daysText.split(',').map((e) => int.parse(e)).toList(),
      completedAt:
          completed == null ? null : DateTime.fromMillisecondsSinceEpoch(completed),
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    );
  }

  Task clone() => Task(
        id: id,
        title: title,
        description: description,
        category: category,
        priority: priority,
        dueAt: dueAt,
        isDone: isDone,
        hasReminder: hasReminder,
        isImportant: isImportant,
        repeat: repeat,
        repeatDays: [...repeatDays],
        completedAt: completedAt,
        createdAt: createdAt,
        subtasks: subtasks
            .map((s) => Subtask(id: s.id, title: s.title, done: s.done))
            .toList(),
      );
}

/// The next date/time a repeating task should be due after it was completed.
DateTime nextOccurrence(Task t) {
  final todayStart = dayOnly(DateTime.now());
  var next = t.dueAt;
  for (var i = 0; i < 800; i++) {
    next = DateTime(next.year, next.month, next.day + 1, t.dueAt.hour, t.dueAt.minute);
    final okDate = next.isAfter(t.dueAt) && !next.isBefore(todayStart);
    if (!okDate) continue;
    if (t.repeat == Repeat.daily) return next;
    if (t.repeat == Repeat.weekly && t.repeatDays.contains(next.weekday)) {
      return next;
    }
  }
  return t.dueAt.add(const Duration(days: 1));
}
