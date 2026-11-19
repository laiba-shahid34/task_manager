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
    try {
      await Notifier.init();
    } catch (_) {
      // the app still works without notifications
    }

    final state = AppState();
    await state.init();
    Notifier.onDone = (id) => state.completeFromNotification(id);
    final launchedDone = await Notifier.launchedWithDone();
    if (launchedDone != null) await state.completeFromNotification(launchedDone);
    // keep reminders alive across restarts (after the first screen is shown)
    Future<void>.delayed(const Duration(seconds: 3), state.rescheduleAll);

    runApp(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: DreamyApp(showWelcome: !state.onboarded),
      ),
    );
  } catch (e, st) {
    // show the problem instead of a blank page
    runApp(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: SelectableText('Startup error:\n$e\n\n$st')),
        ),
      ),
    ));
  }
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
