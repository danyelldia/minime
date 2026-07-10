import 'package:flutter/material.dart';

import '../models/bill_item.dart';

class BillCard extends StatelessWidget {
  final BillItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleSettled;

  const BillCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleSettled,
  });

  String get _settledLabel {
    switch (item.category) {
      case BillCategory.bill:
        return 'Platita';
      case BillCategory.income:
        return 'Primit';
      case BillCategory.wanted:
        return 'Cumparat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: item.isSettled,
          onChanged: (_) => onToggleSettled(),
        ),
        title: Text(
          item.name,
          style: TextStyle(decoration: item.isSettled ? TextDecoration.lineThrough : null),
        ),
        subtitle: item.isSettled
            ? Text(_settledLabel)
            : item.dueDate != null
                ? Text('Scadent: ${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}')
                : null,
        trailing: Text(
          '${item.amount.toStringAsFixed(2)} lei',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
