import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/category.dart';

/// Gestioneaza categoriile si subcategoriile: incarcare din DB, adaugare,
/// editare si stergere (in cascada, cu subcategorii si notite/to-do asociate).
class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _loaded = false;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoaded => _loaded;

  List<Category> get mainCategories =>
      _categories.where((c) => c.isMainCategory).toList();

  List<Category> subcategoriesOf(String parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  Category? byId(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('categories');
    _categories = rows.map((r) => Category.fromMap(r)).toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', category.toMap());
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories[idx] = category;
    notifyListeners();
  }

  /// Sterge categoria si, in cascada, subcategoriile ei si toate
  /// notitele/to-do-urile asociate (direct categoriei sau subcategoriilor).
  Future<void> deleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    final subIds = subcategoriesOf(id).map((c) => c.id).toList();
    final allIds = [id, ...subIds];

    for (final catId in allIds) {
      await db.delete('note_tasks', where: 'categoryId = ?', whereArgs: [catId]);
    }
    for (final catId in subIds) {
      await db.delete('categories', where: 'id = ?', whereArgs: [catId]);
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);

    _categories.removeWhere((c) => allIds.contains(c.id));
    notifyListeners();
  }
}
