import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/priority_tag.dart';

/// Singleton for MiniMe's local SQLite database (sqflite).
/// All MiniMe data (categories, tags, notes/to-dos, bills, history,
/// profile) stays local on the phone - nothing is sent anywhere, except
/// for the optional Google Calendar sync (future phase).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const int dbVersion = 2;

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
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        durationUnit TEXT,
        dueDate TEXT,
        reminderTime TEXT,
        recurrenceRule TEXT,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        googleCalendarEventId TEXT,
        parentTaskId TEXT,
        tags TEXT,
        isUrgent INTEGER NOT NULL DEFAULT 0,
        isImportant INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        locationName TEXT,
        locationLat REAL,
        locationLng REAL,
        locationRadius REAL,
        locationLastTriggeredDate TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (priorityTagId) REFERENCES priority_tags (id),
        FOREIGN KEY (parentTaskId) REFERENCES note_tasks (id)
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

    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        birthDate TEXT,
        maritalStatus TEXT,
        spouseName TEXT,
        hasKids INTEGER NOT NULL DEFAULT 0,
        kidsNames TEXT,
        hasPets INTEGER NOT NULL DEFAULT 0,
        petsNames TEXT,
        onboardingDone INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_facts (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // seed: default main categories and priority tags
    for (final cat in defaultMainCategories()) {
      await db.insert('categories', cat.toMap());
    }
    for (final tag in defaultPriorityTags()) {
      await db.insert('priority_tags', tag.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const newColumns = <String>[
        'ALTER TABLE note_tasks ADD COLUMN durationUnit TEXT',
        'ALTER TABLE note_tasks ADD COLUMN parentTaskId TEXT',
        'ALTER TABLE note_tasks ADD COLUMN tags TEXT',
        'ALTER TABLE note_tasks ADD COLUMN isUrgent INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE note_tasks ADD COLUMN isImportant INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE note_tasks ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE note_tasks ADD COLUMN locationName TEXT',
        'ALTER TABLE note_tasks ADD COLUMN locationLat REAL',
        'ALTER TABLE note_tasks ADD COLUMN locationLng REAL',
        'ALTER TABLE note_tasks ADD COLUMN locationRadius REAL',
        'ALTER TABLE note_tasks ADD COLUMN locationLastTriggeredDate TEXT',
      ];
      for (final stmt in newColumns) {
        try {
          await db.execute(stmt);
        } catch (_) {
          // column already exists - ignore, keeps upgrade idempotent
        }
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id TEXT PRIMARY KEY,
          name TEXT,
          birthDate TEXT,
          maritalStatus TEXT,
          spouseName TEXT,
          hasKids INTEGER NOT NULL DEFAULT 0,
          kidsNames TEXT,
          hasPets INTEGER NOT NULL DEFAULT 0,
          petsNames TEXT,
          onboardingDone INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS profile_facts (
          id TEXT PRIMARY KEY,
          text TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
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
