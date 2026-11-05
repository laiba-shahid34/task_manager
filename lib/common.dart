import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ------------------------------------------------------------------
//  Colour palette for light + dark mode
// ------------------------------------------------------------------
class Pal {
  final bool dark;
  final Color bg;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;
  final Color soft;
  final Color border;

  const Pal({
    required this.dark,
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
    required this.soft,
    required this.border,
  });

  static const Pal light = Pal(
    dark: false,
    bg: Color(0xFFF7F2FF),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF2E2250),
    sub: Color(0xFF7D6FA8),
    primary: Color(0xFF8A56EF),
    soft: Color(0xFFEDE3FF),
    border: Color(0xFFE4D8FF),
  );

  static const Pal darkPal = Pal(
    dark: true,
    bg: Color(0xFF120D22),
    card: Color(0xFF1F1736),
    text: Color(0xFFF2ECFF),
    sub: Color(0xFFA997D8),
    primary: Color(0xFFA67CFF),
    soft: Color(0xFF30245A),
    border: Color(0xFF3B2D68),
  );

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPal : light;

  List<Color> get bgGradient => dark
      ? const [Color(0xFF1B1238), Color(0xFF120D22)]
      : const [Color(0xFFEBDFFF), Color(0xFFFCF8FF)];

  List<Color> get heroGradient => dark
      ? const [Color(0xFF5B3FC0), Color(0xFF8A4FC9)]
      : const [Color(0xFF8A56EF), Color(0xFFB98BF2)];
}

ThemeData buildTheme(Brightness b) {
  final pal = b == Brightness.dark ? Pal.darkPal : Pal.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A56EF),
      brightness: b,
    ),
    scaffoldBackgroundColor: pal.bg,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: pal.card,
      indicatorColor: pal.soft,
    ),
  );
}

// ------------------------------------------------------------------
//  Categories + priorities
// ------------------------------------------------------------------
class CategoryInfo {
  final String key;
  final String emoji;
  final Color color;
  const CategoryInfo(this.key, this.emoji, this.color);
}

const List<CategoryInfo> kCategories = [
  CategoryInfo('Study', '📚', Color(0xFF8A56EF)),
  CategoryInfo('Personal', '💖', Color(0xFFE5578A)),
  CategoryInfo('Work', '💼', Color(0xFF3F8EF2)),
  CategoryInfo('Health', '💧', Color(0xFF28B6A5)),
  CategoryInfo('Shopping', '🛍️', Color(0xFFF2A33A)),
  CategoryInfo('Home', '🏡', Color(0xFF6BBF59)),
  CategoryInfo('Other', '✨', Color(0xFF9A8FB8)),
];

CategoryInfo catInfo(String key) =>
    kCategories.firstWhere((c) => c.key == key, orElse: () => kCategories.last);

const List<String> kPriorityNames = ['Low', 'Medium', 'High'];

Color priorityColor(int p) {
  switch (p) {
    case 2:
      return const Color(0xFFE5578A);
    case 1:
      return const Color(0xFF3DB67B);
    default:
      return const Color(0xFFF2A33A);
  }
}

const List<String> kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> kWeekdayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

// ------------------------------------------------------------------
//  Date helpers
// ------------------------------------------------------------------
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String timeLabel(DateTime d) => DateFormat('h:mm a').format(d);

String dateLabel(DateTime d) {
  final now = DateTime.now();
  final time = timeLabel(d);
  if (sameDay(d, now)) return 'Today, $time';
  if (sameDay(d, now.add(const Duration(days: 1)))) return 'Tomorrow, $time';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday, $time';
  }
  return '${DateFormat('d MMM').format(d)}, $time';
}
