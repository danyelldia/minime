import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../widgets/bill_card.dart';
import 'bill_edit_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bills / Income / Wanted'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bills'),
              Tab(text: 'Income'),
              Tab(text: 'Wanted'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BillList(category: BillCategory.bill),
            _BillList(category: BillCategory.income),
            _BillList(category: BillCategory.wanted),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(ctx).index;
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => BillEditScreen(
                      defaultCategory: BillCategory.values[tabIndex],
                    ),
                  ),
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

  String _label(BillCategory c) {
    switch (c) {
      case BillCategory.bill:
        return 'Total neplatit';
      case BillCategory.income:
        return 'Total asteptat';
      case BillCategory.wanted:
        return 'Cost total ramas';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(_label(category), style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${total.toStringAsFixed(2)} lei',
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
              ? const Center(child: Text('Nimic aici inca'))
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
