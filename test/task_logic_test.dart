import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/common.dart';
import 'package:task_manager/models.dart';

Task _task({
  DateTime? due,
  Repeat repeat = Repeat.none,
  List<int>? days,
  bool done = false,
}) =>
    Task(
      id: 1,
      title: 'Test task',
      dueAt: due ?? DateTime.now().add(const Duration(hours: 1)),
      repeat: repeat,
      repeatDays: days,
      isDone: done,
    );

void main() {
  group('Task model', () {
    test('toMap and fromMap keep every field', () {
      final due = DateTime(2026, 11, 20, 9, 30);
      final t = Task(
        id: 7,
        title: 'Read chapter 3',
        description: 'Pages 40-60',
        category: 'Study',
        priority: 2,
        dueAt: due,
        isImportant: true,
        repeat: Repeat.weekly,
        repeatDays: [1, 3, 5],
      );

      final copy = Task.fromMap(t.toMap());

      expect(copy.id, 7);
      expect(copy.title, 'Read chapter 3');
      expect(copy.description, 'Pages 40-60');
      expect(copy.category, 'Study');
      expect(copy.priority, 2);
      expect(copy.dueAt, due);
      expect(copy.isImportant, isTrue);
      expect(copy.isDone, isFalse);
      expect(copy.hasReminder, isTrue);
      expect(copy.repeat, Repeat.weekly);
      expect(copy.repeatDays, [1, 3, 5]);
    });

    test('clone is independent of the original', () {
      final t = _task(repeat: Repeat.weekly, days: [2]);
      t.subtasks.add(Subtask(title: 'a'));
      final c = t.clone();
      c.repeatDays.add(4);
      c.subtasks.first.done = true;

      expect(t.repeatDays, [2]);
      expect(t.subtasks.first.done, isFalse);
    });

    test('isOverdue only for unfinished tasks in the past', () {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      expect(_task(due: past).isOverdue, isTrue);
      expect(_task(due: past, done: true).isOverdue, isFalse);
      expect(_task().isOverdue, isFalse);
    });
  });

  group('Progress tracking', () {
    test('task without subtasks is 0% or 100%', () {
      expect(_task().progress, 0.0);
      expect(_task(done: true).progress, 1.0);
    });

    test('progress follows finished subtasks', () {
      final t = _task();
      t.subtasks.addAll([
        Subtask(title: 'one', done: true),
        Subtask(title: 'two'),
        Subtask(title: 'three'),
        Subtask(title: 'four', done: true),
      ]);
      expect(t.doneSubtasks, 2);
      expect(t.progress, 0.5);
    });
  });

  group('Repeat tasks', () {
    test('labels', () {
      expect(_task().repeatLabel, 'Does not repeat');
      expect(_task(repeat: Repeat.daily).repeatLabel, 'Every day');
      final weekly = _task(repeat: Repeat.weekly, days: [1, 3]).repeatLabel;
      expect(weekly, 'Every Mon, Wed');
    });

    test('daily task moves to a later day at the same time', () {
      final due = DateTime.now().subtract(const Duration(days: 3));
      final t = _task(
        due: DateTime(due.year, due.month, due.day, 9, 15),
        repeat: Repeat.daily,
      );
      final next = nextOccurrence(t);

      expect(next.isAfter(t.dueAt), isTrue);
      expect(next.isBefore(dayOnly(DateTime.now())), isFalse);
      expect(next.hour, 9);
      expect(next.minute, 15);
    });

    test('weekly task lands only on the chosen weekday', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final past = DateTime.now().subtract(const Duration(days: 3));
      final t = _task(
        due: DateTime(past.year, past.month, past.day, 18, 0),
        repeat: Repeat.weekly,
        days: [tomorrow.weekday],
      );
      final next = nextOccurrence(t);

      expect(next.weekday, tomorrow.weekday);
      expect(next.isAfter(t.dueAt), isTrue);
      expect(next.hour, 18);
    });
  });

  group('Date helpers', () {
    test('sameDay ignores the time', () {
      expect(sameDay(DateTime(2026, 5, 1, 1), DateTime(2026, 5, 1, 23)), isTrue);
      expect(sameDay(DateTime(2026, 5, 1), DateTime(2026, 5, 2)), isFalse);
    });

    test('dayOnly drops the time', () {
      expect(dayOnly(DateTime(2026, 5, 1, 13, 45)), DateTime(2026, 5, 1));
    });
  });
}
