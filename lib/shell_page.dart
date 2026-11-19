import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'calendar_page.dart';
import 'art.dart';
import 'common.dart';
import 'home_page.dart';
import 'notifier.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'task_form_page.dart';

/// Bottom navigation: Home, Calendar, Stats, Settings.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Notifier.requestPermissions();
      context.read<AppState>().startMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // pause the music when the app goes to the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final s = context.read<AppState>();
    if (state == AppLifecycleState.paused) {
      s.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      s.resumeMusic();
    }
  }

  void _addTask() {
    final s = context.read<AppState>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskFormPage(
          initialDate: _index == 1 ? s.selectedDay : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    final wide = MediaQuery.of(context).size.width >= 800;

    const pages = [
      HomePage(),
      CalendarPage(),
      StatsPage(),
      SettingsPage(),
    ];
    final stack = IndexedStack(index: _index, children: pages);

    // On a wide screen (web / tablet) the menu moves to the left side and the
    // content is centred in a comfortable width.
    final Widget body = wide
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: pal.card.withValues(alpha: 0.88),
                indicatorColor: pal.soft,
                minWidth: 92,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 18, bottom: 12),
                  child: BearAvatar(size: 52),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: Text('Calendar'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: Text('Stats'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Settings'),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _index >= 2 ? 1120 : 820,
                    ),
                    child: stack,
                  ),
                ),
              ),
            ],
          )
        : stack;

    return Scaffold(
      body: ThemedBackdrop(
        child: SafeArea(
          bottom: false,
          child: body,
        ),
      ),
      floatingActionButton: _index <= 1
          ? FloatingActionButton(
              onPressed: _addTask,
              backgroundColor: pal.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
