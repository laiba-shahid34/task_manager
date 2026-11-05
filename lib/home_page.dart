import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'art.dart';
import 'common.dart';
import 'models.dart';
import 'task_detail_page.dart';
import 'widgets.dart';

enum HomeFilter { all, today, pending, completed, important, repeating, overdue }

const Map<HomeFilter, String> _filterLabels = {
  HomeFilter.all: 'All',
  HomeFilter.today: 'Today',
  HomeFilter.pending: 'Pending',
  HomeFilter.completed: 'Completed',
  HomeFilter.important: '⭐ Important',
  HomeFilter.repeating: '🔁 Repeating',
  HomeFilter.overdue: '⏳ Overdue',
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeFilter _filter = HomeFilter.all;
  String? _category;
  int _sort = 0; // 0 date, 1 priority, 2 title
  bool _searching = false;
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Task> _visible(AppState s) {
    final now = DateTime.now();
    final q = _query.text.trim().toLowerCase();

    final list = s.tasks.where((t) {
      final byFilter = switch (_filter) {
        HomeFilter.all => true,
        HomeFilter.today => sameDay(t.dueAt, now),
        HomeFilter.pending => !t.isDone,
        HomeFilter.completed => t.isDone,
        HomeFilter.important => t.isImportant,
        HomeFilter.repeating => t.repeat != Repeat.none,
        HomeFilter.overdue => t.isOverdue,
      };
      if (!byFilter) return false;
      if (_category != null && t.category != _category) return false;
      if (q.isNotEmpty &&
          !t.title.toLowerCase().contains(q) &&
          !t.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      switch (_sort) {
        case 1:
          final c = b.priority.compareTo(a.priority);
          return c != 0 ? c : a.dueAt.compareTo(b.dueAt);
        case 2:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        default:
          return a.dueAt.compareTo(b.dueAt);
      }
    });
    return list;
  }

  Future<void> _delete(Task t) async {
    final s = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await s.deleteTask(t);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${removed.title}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => s.restoreTask(removed),
        ),
      ),
    );
  }

  void _open(Task t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailPage(taskId: t.id!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);
    final visible = _visible(s);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        _header(s, pal),
        const SizedBox(height: 14),
        TodayCard(done: s.todayDone, total: s.todayTotal),
        const SizedBox(height: 14),
        if (_searching) ...[
          _searchField(pal),
          const SizedBox(height: 12),
        ],
        _filterChips(pal),
        const SizedBox(height: 8),
        _categoryAndSort(pal),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          EmptyState(
            title: s.tasks.isEmpty ? 'No tasks yet' : 'Nothing here',
            subtitle: s.tasks.isEmpty
                ? 'Tap the + button to plan something magical ✨'
                : 'Try another filter or search 💜',
          )
        else
          for (final t in visible) _dismissible(s, t),
      ],
    );
  }

  // ---------------- header ----------------
  Widget _header(AppState s, Pal pal) {
    final overdue = s.overdueCount;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mood = s.totalCount == 0
        ? 'Ready to plan your day? 💜'
        : s.todayTotal > 0 && s.todayDone == s.todayTotal
            ? "You finished today's tasks! 🎉"
            : "You're doing great today! 💜";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${s.userName}! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: pal.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(mood, style: TextStyle(color: pal.sub, fontSize: 13.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roundIcon(
                      icon: s.musicOn
                          ? Icons.music_note_rounded
                          : Icons.music_off_rounded,
                      pal: pal,
                      tooltip: 'Music',
                      onTap: () => s.setMusicOn(!s.musicOn),
                    ),
                    const SizedBox(width: 8),
                    _roundIcon(
                      icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      pal: pal,
                      tooltip: 'Light / dark',
                      onTap: () =>
                          s.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
                    ),
                    const SizedBox(width: 8),
                    _roundIcon(
                      icon: Icons.search_rounded,
                      pal: pal,
                      tooltip: 'Search',
                      onTap: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) _query.clear();
                      }),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _roundIcon(
                          icon: Icons.notifications_rounded,
                          pal: pal,
                          tooltip: 'Overdue',
                          onTap: () {
                            if (overdue == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No overdue tasks 🎉')),
                              );
                            } else {
                              setState(() => _filter = HomeFilter.overdue);
                            }
                          },
                        ),
                        if (overdue > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5578A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$overdue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        const CatWidget(size: 112, awake: true),
      ],
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required Pal pal,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: pal.soft,
            shape: BoxShape.circle,
            border: Border.all(color: pal.border),
          ),
          child: Icon(icon, size: 20, color: pal.primary),
        ),
      ),
    );
  }

  Widget _searchField(Pal pal) {
    return TextField(
      controller: _query,
      autofocus: true,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: pal.text),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        hintStyle: TextStyle(color: pal.sub),
        prefixIcon: Icon(Icons.search_rounded, color: pal.primary),
        filled: true,
        fillColor: pal.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: pal.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: pal.border),
        ),
      ),
    );
  }

  // ---------------- filters ----------------
  Widget _filterChips(Pal pal) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in HomeFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_filterLabels[f]!),
                selected: _filter == f,
                showCheckmark: false,
                selectedColor: pal.primary,
                backgroundColor: pal.card,
                side: BorderSide(color: pal.border),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _filter == f ? Colors.white : pal.text,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryAndSort(Pal pal) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All categories'),
                    selected: _category == null,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: pal.soft,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: pal.border),
                    labelStyle: TextStyle(fontSize: 12, color: pal.text),
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in kCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${c.emoji} ${c.key}'),
                      selected: _category == c.key,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: c.color.withValues(alpha: 0.25),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: pal.border),
                      labelStyle: TextStyle(fontSize: 12, color: pal.text),
                      onSelected: (_) => setState(
                          () => _category = _category == c.key ? null : c.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'Sort',
          icon: Icon(Icons.sort_rounded, color: pal.primary),
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(value: 0, checked: _sort == 0, child: const Text('Sort by date')),
            CheckedPopupMenuItem(value: 1, checked: _sort == 1, child: const Text('Sort by priority')),
            CheckedPopupMenuItem(value: 2, checked: _sort == 2, child: const Text('Sort by title')),
          ],
        ),
      ],
    );
  }

  // ---------------- list item with swipe ----------------
  Widget _dismissible(AppState s, Task t) {
    return Dismissible(
      key: ValueKey('task_${t.id}'),
      background: _swipeBg(
        color: const Color(0xFF3DB67B),
        icon: Icons.check_circle_rounded,
        label: t.isDone ? 'Undo' : 'Done',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: const Color(0xFFE5578A),
        icon: Icons.delete_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await s.toggleDone(t);
          return false; // stays in the list
        }
        return true;
      },
      onDismissed: (_) => _delete(t),
      child: TaskTile(
        task: t,
        onTap: () => _open(t),
        onToggle: () => s.toggleDone(t),
        onStar: () => s.toggleImportant(t),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
