import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/bill_item.dart';

/// Manages the Dashboard's financial section: bills, income (money
/// expected), and the shopping list.
class BillProvider extends ChangeNotifier {
  List<BillItem> _items = [];

  List<BillItem> get items => List.unmodifiable(_items);

  List<BillItem> byCategory(BillCategory category) =>
      _items.where((b) => b.category == category).toList();

  double _unsettledTotal(BillCategory category) => byCategory(category)
      .where((b) => !b.isSettled)
      .fold(0.0, (sum, b) => sum + b.amount);

  double get totalUnpaidBills => _unsettledTotal(BillCategory.bill);
  double get totalExpectedIncome => _unsettledTotal(BillCategory.income);
  double get totalShoppingCost => _unsettledTotal(BillCategory.shopping);

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('bill_items');
    _items = rows.map((r) => BillItem.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addItem(BillItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('bill_items', item.toMap());
    _items.add(item);
    notifyListeners();
  }

  Future<void> updateItem(BillItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('bill_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    final idx = _items.indexWhere((b) => b.id == item.id);
    if (idx != -1) _items[idx] = item;
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('bill_items', where: 'id = ?', whereArgs: [id]);
    _items.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> toggleSettled(BillItem item) async {
    await updateItem(item.copyWith(isSettled: !item.isSettled));
  }
}
