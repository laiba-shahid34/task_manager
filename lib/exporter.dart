import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'common.dart';

/// Export tasks as CSV / PDF and hand the file to the Android share sheet
/// (pick Gmail there to send it by email).
class Exporter {
  static String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static String _status(Task t) =>
      t.isDone ? 'Completed' : (t.isOverdue ? 'Overdue' : 'Pending');

  static String _csvCell(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    final safe = v.replaceAll('"', '""');
    return needsQuotes ? '"$safe"' : safe;
  }

  static String buildCsv(List<Task> tasks) {
    final f = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<String>>[
      [
        'Title',
        'Description',
        'Category',
        'Priority',
        'Due',
        'Status',
        'Repeat',
        'Subtasks done',
        'Completed at',
      ],
      for (final t in tasks)
        [
          t.title,
          t.description,
          t.category,
          kPriorityNames[t.priority],
          f.format(t.dueAt),
          _status(t),
          t.repeatLabel,
          '${t.doneSubtasks}/${t.subtasks.length}',
          t.completedAt == null ? '' : f.format(t.completedAt!),
        ],
    ];
    return rows.map((r) => r.map(_csvCell).join(',')).join('\n');
  }

  static Future<File> writeCsv(List<Task> tasks) async {
    final file = File('${Directory.systemTemp.path}/tasks_${_stamp()}.csv');
    await file.writeAsString(buildCsv(tasks));
    return file;
  }

  // The built-in PDF font has no emoji, so keep plain Latin characters only.
  static String _plain(String s) =>
      String.fromCharCodes(s.runes.where((r) => r < 256));

  static Future<Uint8List> buildPdf(List<Task> tasks, String userName) async {
    final f = DateFormat('d MMM yyyy, h:mm a');
    final doc = pw.Document();

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            _plain(text),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    final done = tasks.where((t) => t.isDone).length;

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Task Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(_plain('For $userName - ${f.format(DateTime.now())}')),
          pw.SizedBox(height: 4),
          pw.Text('${tasks.length} tasks, $done completed'),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(2.2),
              4: const pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(children: [
                cell('Title', bold: true),
                cell('Category', bold: true),
                cell('Priority', bold: true),
                cell('Due', bold: true),
                cell('Status', bold: true),
              ]),
              for (final t in tasks)
                pw.TableRow(children: [
                  cell(t.subtasks.isEmpty
                      ? t.title
                      : '${t.title} (${t.doneSubtasks}/${t.subtasks.length})'),
                  cell(t.category),
                  cell(kPriorityNames[t.priority]),
                  cell(f.format(t.dueAt)),
                  cell(_status(t)),
                ]),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<File> writePdf(List<Task> tasks, String userName) async {
    final bytes = await buildPdf(tasks, userName);
    final file = File('${Directory.systemTemp.path}/tasks_${_stamp()}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> share(File file, String mime) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: 'My tasks',
        text: 'My task list from Dreamy Task Manager',
      ),
    );
  }
}
