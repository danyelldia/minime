import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';

/// Exports all of MiniMe's local data (categories, tags, notes/to-dos,
/// bills, history, profile) as a single JSON file, then opens the
/// system share sheet so the user can save it wherever they like
/// (Drive, email, a file manager, etc). Everything stays on-device
/// until the user chooses where to send it.
class ExportService {
  ExportService._();

  static Future<File> buildExportFile() async {
    final db = await DatabaseHelper.instance.database;

    final data = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': await db.query('categories'),
      'priority_tags': await db.query('priority_tags'),
      'note_tasks': await db.query('note_tasks'),
      'bill_items': await db.query('bill_items'),
      'history_entries': await db.query('history_entries'),
      'user_profile': await db.query('user_profile'),
      'profile_facts': await db.query('profile_facts'),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/minime_backup_$timestamp.json');
    await file.writeAsString(jsonStr);
    return file;
  }

  static Future<void> exportAndShare() async {
    final file = await buildExportFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'MiniMe backup',
    );
  }
}
