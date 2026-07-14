import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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

  String _settledLabel(AppLocalizations l10n) {
    switch (item.category) {
      case BillCategory.bill:
        return l10n.billPaid;
      case BillCategory.income:
        return l10n.billReceived;
      case BillCategory.shopping:
        return l10n.billBought;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            ? Text(_settledLabel(l10n))
            : item.dueDate != null
                ? Text(l10n.billDueDate(
                    '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}'))
                : null,
        trailing: Text(
          l10n.billCardAmount(item.amount.toStringAsFixed(2)),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
