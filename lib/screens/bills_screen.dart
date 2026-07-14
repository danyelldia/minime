import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../widgets/bill_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'bill_edit_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.billsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.billsTabBills),
              Tab(text: l10n.billsTabIncome),
              Tab(text: l10n.billsTabShopping),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BillList(category: BillCategory.bill),
            _BillList(category: BillCategory.income),
            _BillList(category: BillCategory.shopping),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(ctx).index;
                final category = BillCategory.values[tabIndex];
                showQuickAddSheet(
                  ctx,
                  initialKind:
                      category == BillCategory.shopping ? QuickAddKind.shopping : QuickAddKind.bill,
                );
              },
              child: const Icon(Icons.add_rounded),
            );
          },
        ),
      ),
    );
  }
}

class _BillList extends StatelessWidget {
  final BillCategory category;
  const _BillList({required this.category});

  String _label(AppLocalizations l10n, BillCategory c) {
    switch (c) {
      case BillCategory.bill:
        return l10n.billsTotalUnpaid;
      case BillCategory.income:
        return l10n.billsTotalExpected;
      case BillCategory.shopping:
        return l10n.billsTotalRemaining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<BillProvider>();
    final items = provider.byCategory(category);
    final total = items.where((b) => !b.isSettled).fold(0.0, (s, b) => s + b.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label(l10n, category), style: Theme.of(context).textTheme.titleSmall),
              Text(
                l10n.billCardAmount(total.toStringAsFixed(2)),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(l10n.billsNothingHere))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return BillCard(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BillEditScreen(existing: item)),
                      ),
                      onToggleSettled: () => provider.toggleSettled(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
