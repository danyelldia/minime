enum BillCategory { bill, income, shopping }

/// An item in the Dashboard's financial section:
/// - bill: a bill to pay
/// - income: money you're expecting
/// - shopping: something on your shopping list
class BillItem {
  final String id;
  final String name;
  final double amount;
  final BillCategory category;
  final DateTime? dueDate;
  final bool isSettled; // paid / received / bought
  final String? notes;

  const BillItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.dueDate,
    this.isSettled = false,
    this.notes,
  });

  BillItem copyWith({
    String? name,
    double? amount,
    BillCategory? category,
    DateTime? dueDate,
    bool? isSettled,
    String? notes,
  }) {
    return BillItem(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category.name,
        'dueDate': dueDate?.toIso8601String(),
        'isSettled': isSettled ? 1 : 0,
        'notes': notes,
      };

  factory BillItem.fromMap(Map<String, dynamic> map) {
    // 'wanted' was the old name for this category (pre Faza 6) - kept for
    // backward compatibility with rows created by earlier builds.
    final rawCategory = map['category'] as String;
    final category = rawCategory == 'wanted'
        ? BillCategory.shopping
        : BillCategory.values.byName(rawCategory);
    return BillItem(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: category,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isSettled: (map['isSettled'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }
}
