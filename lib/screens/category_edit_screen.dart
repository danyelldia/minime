import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/color_swatch_picker.dart';
import '../widgets/icon_picker.dart';

class CategoryEditScreen extends StatefulWidget {
  final Category? existing;
  final String? parentId;

  const CategoryEditScreen({super.key, this.existing, this.parentId});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  late final TextEditingController _nameController;
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _icon = widget.existing?.icon ?? availableCategoryIcons.first;
    _color = widget.existing?.color ?? presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<CategoryProvider>();
    if (widget.existing != null) {
      provider.updateCategory(widget.existing!.copyWith(
        name: name,
        icon: _icon,
        color: _color,
      ));
    } else {
      provider.addCategory(Category(
        id: const Uuid().v4(),
        name: name,
        icon: _icon,
        color: _color,
        parentId: widget.parentId,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSubcategory = widget.parentId != null || widget.existing?.parentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null
            ? 'Editeaza categoria'
            : isSubcategory
                ? 'Subcategorie noua'
                : 'Categorie noua'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nume', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Text('Iconita', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          IconPickerGrid(selected: _icon, onChanged: (i) => setState(() => _icon = i)),
          const SizedBox(height: 24),
          Text('Culoare', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ColorSwatchPicker(selected: _color, onChanged: (c) => setState(() => _color = c)),
          const SizedBox(height: 32),
          FilledButton(onPressed: _save, child: const Text('Salveaza')),
        ],
      ),
    );
  }
}
