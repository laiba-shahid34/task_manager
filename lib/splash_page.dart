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
          Positioned.fill(
            child: Image.asset(
              'assets/images/night_roses.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const NightSky(),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33140C10), Color(0x66140C10), Color(0xDD2A0E1A)],
                ),
              ),
            ),
          ),
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
                  Floating(
                    distance: 6,
                    duration: const Duration(seconds: 3),
                    child: Container(
                      width: 270,
                      height: 198,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE9B872), width: 3),
                        boxShadow: const [
                          BoxShadow(color: Color(0x88E9B872), blurRadius: 26),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/bear_pair.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Text('🧸', style: TextStyle(fontSize: 80))),
                        ),
                      ),
                    ),
                  ),
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
                      shadows: [Shadow(color: Color(0xFFE9B872), blurRadius: 22)],
                    ),
                  ),
                  const Text(
                    'Task Manager ♡',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFE9C7),
                      shadows: [Shadow(color: Color(0xFFE9B872), blurRadius: 22)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Plan  •  Organize  •  Achieve ♡',
                    style: TextStyle(color: Color(0xFFFFE0D6), fontSize: 15, letterSpacing: 0.4),
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
                          colors: [Color(0xFFE9B872), Color(0xFFE8798F)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x88E8798F),
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
