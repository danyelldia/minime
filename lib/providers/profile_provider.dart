import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/user_profile.dart';

/// Manages the user's profile (structured onboarding answers) and the
/// list of free-form facts MiniMe remembers about them.
class ProfileProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  List<ProfileFact> _facts = [];
  bool _loaded = false;

  UserProfile get profile => _profile;
  List<ProfileFact> get facts => List.unmodifiable(_facts);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_profile', where: 'id = ?', whereArgs: ['me']);
    if (rows.isNotEmpty) {
      _profile = UserProfile.fromMap(rows.first);
    }
    final factRows = await db.query('profile_facts', orderBy: 'createdAt DESC');
    _facts = factRows.map((r) => ProfileFact.fromMap(r)).toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _profile = profile;
    notifyListeners();
  }

  Future<void> addFact(String text) async {
    final db = await DatabaseHelper.instance.database;
    final fact = ProfileFact(
      id: 'f_${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      createdAt: DateTime.now(),
    );
    await db.insert('profile_facts', fact.toMap());
    _facts.insert(0, fact);
    notifyListeners();
  }

  Future<void> deleteFact(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('profile_facts', where: 'id = ?', whereArgs: [id]);
    _facts.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
