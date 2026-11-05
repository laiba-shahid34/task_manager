import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'art.dart';
import 'shell_page.dart';

/// Welcome screen: night sky, castle, the purple cat and a Get Started button.
class SplashPage extends StatelessWidget {
  /// true when opened again from Settings (just closes instead of going home)
  final bool replay;
  const SplashPage({super.key, this.replay = false});

  Future<void> _start(BuildContext context) async {
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    await s.completeOnboarding();
    s.startMusic();
    if (replay) {
      nav.pop();
    } else {
      nav.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const ShellPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: NightSky()),
          const Align(
            alignment: Alignment(-0.82, -0.28),
            child: Floating(child: Text('🦋', style: TextStyle(fontSize: 30))),
          ),
          const Align(
            alignment: Alignment(0.85, -0.5),
            child: Floating(
              distance: 10,
              duration: Duration(milliseconds: 2600),
              child: Text('🦋', style: TextStyle(fontSize: 26)),
            ),
          ),
          const Align(
            alignment: Alignment(0.7, -0.12),
            child: Floating(child: Text('✨', style: TextStyle(fontSize: 22))),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const CatWidget(size: 200),
                  const SizedBox(height: 6),
                  const Text(
                    'Dreamy',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 54,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0xFFB57CFF), blurRadius: 22)],
                    ),
                  ),
                  const Text(
                    'Task Manager ♡',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF3E6FF),
                      shadows: [Shadow(color: Color(0xFFB57CFF), blurRadius: 22)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Plan  •  Organize  •  Achieve ♡',
                    style: TextStyle(color: Color(0xFFEBDDFF), fontSize: 15, letterSpacing: 0.4),
                  ),
                  const Spacer(flex: 2),
                  GestureDetector(
                    onTap: () => _start(context),
                    child: Container(
                      height: 58,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9BD2), Color(0xFFB57CFF)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x88B57CFF),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
