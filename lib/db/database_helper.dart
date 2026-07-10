import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/priority_tag.dart';

/// Singleton pentru baza de date locala SQLite (sqflite).
/// Toate datele MiniMe (categorii, tag-uri, notite/to-do, bills, istoric)
/// stau local pe telefon - nu se trimit nicaieri, cu exceptia sincronizarii
/// optionale cu Google Calendar (faza 6).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'minime.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL,
        parentId TEXT,
        FOREIGN KEY (parentId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE priority_tags (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        priorityTagId TEXT,
        urgencyColor INTEGER,
        durationMinutes INTEGER,
        dueDate TEXT,
        reminderTime TEXT,
        recurrenceRule TEXT,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        googleCalendarEventId TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (priorityTagId) REFERENCES priority_tags (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        dueDate TEXT,
        isSettled INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history_entries (
        id TEXT PRIMARY KEY,
        noteTaskId TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        snoozeMinutes INTEGER,
        FOREIGN KEY (noteTaskId) REFERENCES note_tasks (id)
      )
    ''');

    // seed: categorii principale si tag-uri de prioritate implicite
    for (final cat in defaultMainCategories()) {
      await db.insert('categories', cat.toMap());
    }
    for (final tag in defaultPriorityTags()) {
      await db.insert('priority_tags', tag.toMap());
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
