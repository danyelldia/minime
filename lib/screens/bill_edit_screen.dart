import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/bill_item.dart';
import '../providers/bill_provider.dart';

class BillEditScreen extends StatefulWidget {
  final BillItem? existing;
  final BillCategory? defaultCategory;

  const BillEditScreen({super.key, this.existing, this.defaultCategory});

  @override
  State<BillEditScreen> createState() => _BillEditScreenState();
}

class _BillEditScreenState extends State<BillEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late BillCategory _category;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _amountController = TextEditingController(text: e != null ? e.amount.toString() : '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? widget.defaultCategory ?? BillCategory.bill;
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    if (name.isEmpty) return;

    final provider = context.read<BillProvider>();
    final notes = _notesController.text.trim();

    if (widget.existing != null) {
      provider.updateItem(widget.existing!.copyWith(
        name: name,
        amount: amount,
        category: _category,
        dueDate: _dueDate,
        notes: notes.isEmpty ? null : notes,
      ));
    } else {
      provider.addItem(BillItem(
        id: const Uuid().v4(),
        name: name,
        amount: amount,
        category: _category,
        dueDate: _dueDate,
        notes: notes.isEmpty ? null : notes,
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.existing == null) return;
    context.read<BillProvider>().deleteItem(widget.existing!.id);
    Navigator.pop(context);
  }

  String _categoryLabel(BillCategory c) {
    switch (c) {
      case BillCategory.bill:
        return 'Bill (factura)';
      case BillCategory.income:
        return 'Income (venit asteptat)';
      case BillCategory.wanted:
        return 'Wanted (de cumparat)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Editeaza' : 'Adauga'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<BillCategory>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Tip', border: OutlineInputBorder()),
            items: BillCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nume', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Suma (lei)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dueDate == null
                ? 'Fara data'
                : 'Data: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notite (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: _save, child: const Text('Salveaza')),
        ],
      ),
    );
  }
}
