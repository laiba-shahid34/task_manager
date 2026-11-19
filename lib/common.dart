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
    bg: Color(0xFFFFF3F1),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF3A2025),
    sub: Color(0xFF9A6B70),
    primary: Color(0xFFD9577A),
    soft: Color(0xFFFFE3E6),
    border: Color(0xFFF3CDD2),
  );

  static const Pal darkPal = Pal(
    dark: true,
    bg: Color(0xFF2A1B18),
    card: Color(0xFF3A2824),
    text: Color(0xFFFBEAE6),
    sub: Color(0xFFD0A9A4),
    primary: Color(0xFFE8798F),
    soft: Color(0xFF3A2824),
    border: Color(0xFF6B5030),
  );

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPal : light;

  List<Color> get bgGradient => dark
      ? const [Color(0xFF3E2823), Color(0xFF22150F)]
      : const [Color(0xFFFFE6E8), Color(0xFFFFF8F6)];

  List<Color> get heroGradient => dark
      ? const [Color(0xFF9C2F52), Color(0xFF5E2240)]
      : const [Color(0xFFD9577A), Color(0xFFEE9AAE)];
}

ThemeData buildTheme(Brightness b) {
  final pal = b == Brightness.dark ? Pal.darkPal : Pal.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD9577A),
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
  CategoryInfo('Study', '📚', Color(0xFFC0609F)),
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
