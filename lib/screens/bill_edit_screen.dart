import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
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
  bool _saving = false;

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
    // Pazeste impotriva dublu-tap, care ar putea crea 2 intrari identice.
    if (_saving) return;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    if (name.isEmpty) return;

    setState(() => _saving = true);

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

  String _categoryLabel(AppLocalizations l10n, BillCategory c) {
    switch (c) {
      case BillCategory.bill:
        return l10n.billLabelBill;
      case BillCategory.income:
        return l10n.billLabelIncome;
      case BillCategory.shopping:
        return l10n.billLabelShopping;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? l10n.billEditTitleEdit : l10n.billEditTitleAdd),
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
            decoration: InputDecoration(labelText: l10n.billEditType, border: const OutlineInputBorder()),
            items: BillCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(l10n, c))))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.billEditName, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.billEditAmount, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dueDate == null
                ? l10n.billEditNoDate
                : l10n.billEditDateLabel('${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}')),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.billEditNotes,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}
