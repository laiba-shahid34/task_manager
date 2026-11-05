import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'common.dart';
import 'db.dart';
import 'models.dart';
import 'notifier.dart';

/// Everything the screens need: tasks, settings, music.
class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  bool loading = true;

  // settings
  ThemeMode themeMode = ThemeMode.system;
  String userName = 'Laiba';
  bool musicOn = true;
  double musicVolume = 0.35;
  String sound = 'chime'; // chime | bell | soft | default | silent
  bool onboarded = false;

  // calendar tab -> remembered so the + button can pre-fill the date
  DateTime selectedDay = dayOnly(DateTime.now());

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _fx = AudioPlayer();
  bool _musicStarted = false;
  bool _musicStarting = false;

  // ------------------------------------------------------------------
  //  Start-up
  // ------------------------------------------------------------------
  Future<void> init() async {
    final db = Db.i;
    tasks = await db.allTasks();

    final theme = await db.getSetting('theme');
    themeMode = theme == 'dark'
        ? ThemeMode.dark
        : theme == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    userName = (await db.getSetting('name')) ?? 'Laiba';
    musicOn = (await db.getSetting('musicOn')) != '0';
    musicVolume = double.tryParse((await db.getSetting('musicVolume')) ?? '') ?? 0.35;
    sound = (await db.getSetting('sound')) ?? 'chime';
    onboarded = (await db.getSetting('onboarded')) == '1';

    loading = false;
    notifyListeners();
  }

  /// Re-creates every reminder. Called each time the app opens so nothing is
  /// lost (after a restart, an update, or if the phone cleared the alarms).
  Future<void> rescheduleAll() async {
    for (final t in List<Task>.from(tasks)) {
      try {
        await Notifier.schedule(t, sound);
      } catch (e) {
        debugPrint('Reschedule failed for ${t.id}: $e');
      }
    }
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await Db.i.setSetting('onboarded', '1');
  }

  // ------------------------------------------------------------------
  //  Music
  // ------------------------------------------------------------------
  Future<void> startMusic() async {
    if (!musicOn) return;
    if (_musicStarting) return;
    try {
      if (_musicStarted) {
        await _music.resume();
        return;
      }
      _musicStarting = true;
      await _music.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none, // don't get cut by notifications
        ),
      ));
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('music/dreamy.mp3'), volume: musicVolume);
      _musicStarted = true;
    } catch (e) {
      debugPrint('Music error: $e');
      _musicStarted = false;
    } finally {
      _musicStarting = false;
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!musicOn || !_musicStarted) return;
    try {
      await _music.resume();
    } catch (_) {}
  }

  Future<void> setMusicOn(bool v) async {
    musicOn = v;
    notifyListeners();
    await Db.i.setSetting('musicOn', v ? '1' : '0');
    if (v) {
      await startMusic();
    } else {
      await pauseMusic();
    }
  }

  Future<void> setMusicVolume(double v, {bool save = false}) async {
    musicVolume = v;
    notifyListeners();
    try {
      await _music.setVolume(v);
    } catch (_) {}
    if (save) await Db.i.setSetting('musicVolume', v.toString());
  }

  Future<void> previewSound(String s) async {
    if (s == 'default' || s == 'silent') return;
    try {
      await _fx.stop();
      await _fx.play(AssetSource('sounds/$s.wav'));
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  // ------------------------------------------------------------------
  //  Settings
  // ------------------------------------------------------------------
  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await Db.i.setSetting(
        'theme', m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system');
  }

  Future<void> setUserName(String n) async {
    userName = n;
    notifyListeners();
    await Db.i.setSetting('name', n);
  }

  Future<void> setSound(String s) async {
    sound = s;
    notifyListeners();
    await Db.i.setSetting('sound', s);
    for (final t in tasks) {
      await Notifier.schedule(t, sound);
    }
  }

  void selectDay(DateTime d) {
    selectedDay = dayOnly(d);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  //  Task actions
  // ------------------------------------------------------------------
  Task? byId(int id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> saveTask(Task t) async {
    if (t.id == null) {
      t.id = await Db.i.insertTask(t);
      tasks.add(t);
    } else {
      await Db.i.updateTask(t);
      final i = tasks.indexWhere((x) => x.id == t.id);
      if (i >= 0) {
        tasks[i] = t;
      } else {
        tasks.add(t);
      }
    }
    await Notifier.schedule(t, sound);
    notifyListeners();
  }

  Future<void> toggleDone(Task t) async {
    if (!t.isDone && t.repeat != Repeat.none) {
      await _completeRepeating(t);
      return;
    }
    t.isDone = !t.isDone;
    t.completedAt = t.isDone ? DateTime.now() : null;
    if (t.isDone) {
      for (final s in t.subtasks) {
        s.done = true;
      }
    }
    notifyListeners();
    await Db.i.updateTask(t);
    await Notifier.schedule(t, sound);
  }

  /// A repeating task is never "finished": a copy goes to Completed and the
  /// original jumps to its next date with the sub-tasks reset.
  Future<void> _completeRepeating(Task t) async {
    final history = Task(
      title: t.title,
      description: t.description,
      category: t.category,
      priority: t.priority,
      dueAt: t.dueAt,
      isDone: true,
      hasReminder: false,
      isImportant: t.isImportant,
      repeat: Repeat.none,
      completedAt: DateTime.now(),
      subtasks: t.subtasks
          .map((s) => Subtask(title: s.title, done: true))
          .toList(),
    );
    history.id = await Db.i.insertTask(history);
    tasks.add(history);

    t.dueAt = nextOccurrence(t);
    for (final s in t.subtasks) {
      s.done = false;
    }
    notifyListeners();
    await Db.i.updateTask(t);
    await Notifier.schedule(t, sound);
  }

  Future<void> toggleImportant(Task t) async {
    t.isImportant = !t.isImportant;
    notifyListeners();
    await Db.i.updateTask(t);
  }

  Future<void> toggleReminder(Task t) async {
    t.hasReminder = !t.hasReminder;
    notifyListeners();
    await Db.i.updateTask(t);
    await Notifier.schedule(t, sound);
  }

  /// Removes at once (so swipe-to-delete is smooth) and returns the task
  /// so the caller can offer "Undo".
  Future<Task> deleteTask(Task t) async {
    tasks.removeWhere((x) => x.id == t.id);
    notifyListeners();
    await Notifier.cancelFor(t);
    await Db.i.deleteTask(t.id!);
    return t;
  }

  Future<void> restoreTask(Task t) async {
    await Db.i.insertTask(t); // keeps the old id
    tasks.add(t);
    await Notifier.schedule(t, sound);
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    final done = tasks.where((t) => t.isDone).toList();
    tasks.removeWhere((t) => t.isDone);
    notifyListeners();
    for (final t in done) {
      await Db.i.deleteTask(t.id!);
    }
  }

  Future<void> deleteEverything() async {
    for (final t in tasks) {
      await Notifier.cancelFor(t);
    }
    tasks.clear();
    notifyListeners();
    await Db.i.deleteAllTasks();
  }

  // ---------------- subtasks ----------------
  Future<void> toggleSubtask(Task t, Subtask s) async {
    s.done = !s.done;
    notifyListeners();
    if (s.id != null) await Db.i.setSubtaskDone(s.id!, s.done);
  }

  Future<void> addSubtask(Task t, String title) async {
    final s = Subtask(title: title);
    s.id = await Db.i.addSubtask(t.id!, title);
    t.subtasks.add(s);
    notifyListeners();
  }

  Future<void> removeSubtask(Task t, Subtask s) async {
    t.subtasks.remove(s);
    notifyListeners();
    if (s.id != null) await Db.i.deleteSubtask(s.id!);
  }

  // ------------------------------------------------------------------
  //  Numbers for dashboard / stats
  // ------------------------------------------------------------------
  List<Task> tasksOn(DateTime day) =>
      tasks.where((t) => sameDay(t.dueAt, day)).toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  int get totalCount => tasks.length;
  int get doneCount => tasks.where((t) => t.isDone).length;
  int get pendingCount => totalCount - doneCount;
  int get overdueCount => tasks.where((t) => t.isOverdue).length;

  int get todayTotal => tasksOn(DateTime.now()).length;
  int get todayDone => tasksOn(DateTime.now()).where((t) => t.isDone).length;

  /// Tasks completed on each of the last [n] days (oldest first).
  List<int> completedPerDay(int n) {
    final today = dayOnly(DateTime.now());
    return List<int>.generate(n, (i) {
      final day = today.subtract(Duration(days: n - 1 - i));
      return tasks
          .where((t) => t.completedAt != null && sameDay(t.completedAt!, day))
          .length;
    });
  }

  /// Consecutive days (ending today or yesterday) with something completed.
  int get streak {
    final days = <DateTime>{
      for (final t in tasks)
        if (t.completedAt != null) dayOnly(t.completedAt!)
    };
    var d = dayOnly(DateTime.now());
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(d)) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }
}
