import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_task.dart';
import '../providers/category_provider.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../widgets/note_card.dart';
import 'category_edit_screen.dart';
import 'note_edit_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String? _selectedSubId; // null = toate subcategoriile + categoria principala

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();

    final category = categoryProvider.byId(widget.categoryId);
    if (category == null) {
      return const Scaffold(body: Center(child: Text('Categoria nu mai exista')));
    }

    final subcategories = categoryProvider.subcategoriesOf(category.id);
    final relevantCategoryIds = _selectedSubId != null
        ? [_selectedSubId!]
        : [category.id, ...subcategories.map((c) => c.id)];

    final tasks =
        taskProvider.tasks.where((t) => relevantCategoryIds.contains(t.categoryId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: category.color.withOpacity(0.15),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoryEditScreen(existing: category)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, category.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteEditScreen(
              defaultCategoryId: _selectedSubId ?? category.id,
            ),
          ),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Toate'),
                  selected: _selectedSubId == null,
                  onSelected: (_) => setState(() => _selectedSubId = null),
                ),
                ...subcategories.map((sub) => ChoiceChip(
                      avatar: Icon(sub.icon, size: 16),
                      label: Text(sub.name),
                      selected: _selectedSubId == sub.id,
                      onSelected: (_) => setState(() => _selectedSubId = sub.id),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Subcategorie'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryEditScreen(parentId: category.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text('Nimic aici inca', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return NoteTaskCard(
                        task: task,
                        priorityTag: tagProvider.byId(task.priorityTagId),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoteEditScreen(existing: task)),
                        ),
                        onToggleDone: task.type == ItemType.todo
                            ? () => taskProvider.toggleDone(task)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stergi categoria?'),
        content: const Text(
          'Se sterg si subcategoriile si toate notitele/to-do-urile din ele.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuleaza')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(categoryId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Sterge'),
          ),
        ],
      ),
    );
  }
}
