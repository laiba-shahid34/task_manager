import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'common.dart';
import 'notifier.dart';
import 'shell_page.dart';
import 'splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Notifier.init();
  } catch (_) {
    // the app still works without notifications
  }

  final state = AppState();
  await state.init();
  state.rescheduleAll(); // keep reminders alive across restarts

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: DreamyApp(showWelcome: !state.onboarded),
    ),
  );
}

class DreamyApp extends StatelessWidget {
  final bool showWelcome;
  const DreamyApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dreamy Task Manager',
      themeMode: mode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: showWelcome ? const SplashPage() : const ShellPage(),
    );
  }
}
