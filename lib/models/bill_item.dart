enum BillCategory { bill, income, wanted }

/// Un element din sectiunea financiara a Dashboard-ului:
/// - bill: o factura de platit
/// - income: bani pe care ii astepti
/// - wanted: ceva ce vrei sa cumperi
class BillItem {
  final String id;
  final String name;
  final double amount;
  final BillCategory category;
  final DateTime? dueDate;
  final bool isSettled; // platita / primit / cumparat
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

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        id: map['id'] as String,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: BillCategory.values.byName(map['category'] as String),
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
        isSettled: (map['isSettled'] as int) == 1,
        notes: map['notes'] as String?,
      );
}
