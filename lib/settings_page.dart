import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'art.dart';
import 'common.dart';
import 'exporter.dart';
import 'notifier.dart';
import 'splash_page.dart';
import 'widgets.dart';

class _SoundOption {
  final String key;
  final String label;
  final String emoji;
  const _SoundOption(this.key, this.label, this.emoji);
}

const List<_SoundOption> _soundOptions = [
  _SoundOption('chime', 'Dreamy chime', '✨'),
  _SoundOption('bell', 'Crystal bell', '🔔'),
  _SoundOption('soft', 'Soft pluck', '🎵'),
  _SoundOption('alarm', 'Loud alarm (keeps ringing)', '⏰'),
  _SoundOption('default', 'Phone default', '📱'),
  _SoundOption('silent', 'Silent', '🔕'),
];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editName(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.userName);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Your name 💜'),
        content: TextField(controller: c, autofocus: true, maxLength: 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) await s.setUserName(v);
  }

  Future<void> _export(BuildContext context, AppState s, bool pdf) async {
    if (s.tasks.isEmpty) {
      _toast(context, 'No tasks to export yet');
      return;
    }
    try {
      final File file = pdf
          ? await Exporter.writePdf(s.tasks, s.userName)
          : await Exporter.writeCsv(s.tasks);
      await Exporter.share(file, pdf ? 'application/pdf' : 'text/csv');
    } catch (e) {
      if (context.mounted) _toast(context, 'Export failed: $e');
    }
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String text,
    required Future<void> Function() onYes,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) await onYes();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pal = Pal.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          'Settings',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: pal.text),
        ),
        const SizedBox(height: 12),

        // profile
        SoftCard(
          onTap: () => _editName(context, s),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pal.soft,
                  border: Border.all(color: pal.primary, width: 2),
                ),
                child: const ClipOval(child: CatWidget(size: 72, awake: true)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.userName} 💜',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pal.text),
                    ),
                    Text('Dream big ✨  (tap to rename)',
                        style: TextStyle(color: pal.sub, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, color: pal.primary),
            ],
          ),
        ),

        // appearance
        const SectionTitle('Appearance'),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.brightness_6_rounded, color: pal.primary),
                  const SizedBox(width: 10),
                  Text('Theme mode',
                      style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark')),
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_android_rounded),
                        label: Text('Auto')),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
            ],
          ),
        ),

        // music
        const SectionTitle('Music'),
        SoftCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.musicOn,
                onChanged: (v) => s.setMusicOn(v),
                secondary: Icon(Icons.music_note_rounded, color: pal.primary),
                title: Text('Soft background music',
                    style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
                subtitle: Text('A calm dreamy tune while you plan',
                    style: TextStyle(color: pal.sub, fontSize: 12)),
              ),
              Row(
                children: [
                  Icon(Icons.volume_down_rounded, color: pal.sub),
                  Expanded(
                    child: Slider(
                      value: s.musicVolume,
                      min: 0,
                      max: 1,
                      onChanged: s.musicOn ? (v) => s.setMusicVolume(v) : null,
                      onChangeEnd: (v) => s.setMusicVolume(v, save: true),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: pal.sub),
                ],
              ),
            ],
          ),
        ),

        // notifications
        const SectionTitle('Notifications'),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text('Reminder sound',
                    style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              ),
              for (final o in _soundOptions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(o.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(o.label, style: TextStyle(color: pal.text)),
                  trailing: s.sound == o.key
                      ? Icon(Icons.check_circle_rounded, color: pal.primary)
                      : Icon(Icons.circle_outlined, color: pal.sub),
                  onTap: () {
                    s.setSound(o.key);
                    s.previewSound(o.key);
                  },
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text('Keep reminding me until the task is done',
                    style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              ),
              Text(
                'If a task is not completed, you get a reminder again and again '
                'after the due time. Tick the task as done (or press Stop on the '
                'notification) to stop it.',
                style: TextStyle(color: pal.sub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [0, 5, 10, 15, 30, 60])
                    ChoiceChip(
                      label: Text(m == 0 ? 'Off' : m == 60 ? 'Every 1 h' : 'Every $m min'),
                      selected: s.nagMinutes == m,
                      onSelected: (_) => s.setNagMinutes(m),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text('Reminders when the app is closed',
                    style: TextStyle(fontWeight: FontWeight.w700, color: pal.text)),
              ),
              Text(
                'Set Battery to "Unrestricted" (and allow Autostart on Xiaomi, '
                'Oppo, Vivo, Infinix, Tecno, Samsung). Do not swipe the app away '
                'with "Force stop".',
                style: TextStyle(color: pal.sub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: Notifier.openBatterySettings,
                      icon: const Icon(Icons.battery_charging_full_rounded, size: 18),
                      label: const Text('Battery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: Notifier.openAppSettings,
                      icon: const Icon(Icons.settings_applications_rounded, size: 18),
                      label: const Text('App settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Notifier.requestPermissions();
                        final st = await Notifier.status();
                        if (context.mounted) _toast(context, st);
                      },
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Allow'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: pal.primary),
                      onPressed: () async {
                        try {
                          await Notifier.showNow(s.sound);
                        } catch (e) {
                          if (context.mounted) _toast(context, 'Error: $e');
                        }
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Test now'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final err = await Notifier.scheduleTest(s.sound);
                    if (context.mounted) {
                      _toast(
                          context,
                          err == null
                              ? 'Test set! Lock the phone, it rings in 10 seconds ⏳'
                              : 'Could not schedule: $err');
                    }
                  },
                  icon: const Icon(Icons.timer_rounded, size: 18),
                  label: const Text('Test in 10 seconds'),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),

        // data
        const SectionTitle('Your data'),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              _tile(pal, Icons.table_chart_rounded, 'Export as CSV',
                  'Open in Excel / Sheets', () => _export(context, s, false)),
              _tile(pal, Icons.picture_as_pdf_rounded, 'Export as PDF',
                  'A neat printable report', () => _export(context, s, true)),
              _tile(pal, Icons.email_rounded, 'Send by email',
                  'Pick Gmail in the share sheet', () => _export(context, s, true)),
              _tile(pal, Icons.cleaning_services_rounded, 'Clear completed tasks',
                  'Remove everything that is done', () {
                _confirm(
                  context,
                  title: 'Clear completed?',
                  text: 'All completed tasks will be deleted.',
                  onYes: () async {
                    await s.clearCompleted();
                    if (context.mounted) _toast(context, 'Completed tasks cleared ✨');
                  },
                );
              }),
              _tile(pal, Icons.delete_forever_rounded, 'Delete all tasks',
                  'This cannot be undone', () {
                _confirm(
                  context,
                  title: 'Delete everything?',
                  text: 'All your tasks will be permanently removed.',
                  onYes: () async {
                    await s.deleteEverything();
                    if (context.mounted) _toast(context, 'All tasks deleted');
                  },
                );
              }, danger: true),
            ],
          ),
        ),

        // about
        const SectionTitle('About'),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              _tile(pal, Icons.auto_awesome_rounded, 'Replay welcome screen', 'See the dreamy intro again', () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SplashPage(replay: true)),
                );
              }),
              _tile(pal, Icons.info_outline_rounded, 'Dreamy Task Manager', 'Version 1.0  -  made with Flutter 💜', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(Pal pal, IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFE5578A) : pal.primary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: danger ? color : pal.text)),
      subtitle: Text(subtitle, style: TextStyle(color: pal.sub, fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: pal.sub),
    );
  }
}
