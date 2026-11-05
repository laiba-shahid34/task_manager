import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// SQLite storage: tasks, subtasks and small key/value settings.
class Db {
  Db._();
  static final Db i = Db._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'dreamy_tasks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, version) async {
        await d.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT,
            priority INTEGER NOT NULL,
            dueAt INTEGER NOT NULL,
            isDone INTEGER NOT NULL,
            hasReminder INTEGER NOT NULL,
            isImportant INTEGER NOT NULL,
            repeatType INTEGER NOT NULL,
            repeatDays TEXT,
            completedAt INTEGER,
            createdAt INTEGER NOT NULL
          )
        ''');
        await d.execute('''
          CREATE TABLE subtasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER NOT NULL,
            title TEXT NOT NULL,
            done INTEGER NOT NULL
          )
        ''');
        await d.execute(
            'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }

  // ---------------- tasks ----------------
  Future<List<Task>> allTasks() async {
    final d = await db;
    final rows = await d.query('tasks', orderBy: 'dueAt ASC');
    final subRows = await d.query('subtasks', orderBy: 'id ASC');

    final byTask = <int, List<Subtask>>{};
    for (final r in subRows) {
      final list = byTask.putIfAbsent(r['taskId'] as int, () => <Subtask>[]);
      list.add(Subtask(
        id: r['id'] as int,
        title: r['title'] as String,
        done: (r['done'] as int) == 1,
      ));
    }

    return rows.map((r) {
      final t = Task.fromMap(r);
      t.subtasks = byTask[t.id] ?? <Subtask>[];
      return t;
    }).toList();
  }

  Future<int> insertTask(Task t) async {
    final d = await db;
    final id = await d.insert('tasks', t.toMap());
    for (final s in t.subtasks) {
      s.id = await d.insert('subtasks', {
        'taskId': id,
        'title': s.title,
        'done': s.done ? 1 : 0,
      });
    }
    return id;
  }

  Future<void> updateTask(Task t) async {
    final d = await db;
    await d.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    await d.delete('subtasks', where: 'taskId = ?', whereArgs: [t.id]);
    for (final s in t.subtasks) {
      s.id = await d.insert('subtasks', {
        'taskId': t.id,
        'title': s.title,
        'done': s.done ? 1 : 0,
      });
    }
  }

  Future<void> deleteTask(int id) async {
    final d = await db;
    await d.delete('subtasks', where: 'taskId = ?', whereArgs: [id]);
    await d.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTasks() async {
    final d = await db;
    await d.delete('subtasks');
    await d.delete('tasks');
  }

  // ---------------- subtasks ----------------
  Future<int> addSubtask(int taskId, String title) async {
    final d = await db;
    return d.insert('subtasks', {'taskId': taskId, 'title': title, 'done': 0});
  }

  Future<void> setSubtaskDone(int id, bool done) async {
    final d = await db;
    await d.update('subtasks', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSubtask(int id) async {
    final d = await db;
    await d.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- settings ----------------
  Future<String?> getSetting(String key) async {
    final d = await db;
    final rows = await d.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
