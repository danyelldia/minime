import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/note_task_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'category_detail_screen.dart';
import 'category_edit_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();
    // "Quick Notes" e o categorie reala (ca sa poata fi aleasa din
    // dropdown-ul de categorie la editare), dar nu apare aici ca "a 4-a
    // categorie mare" - notitele rapide se vad prin link-ul dedicat de pe
    // Dashboard.
    final mainCategories =
        categoryProvider.mainCategories.where((c) => c.id != quickNotesCategoryId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & To-Do'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New category',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryEditScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddSheet(context, initialKind: QuickAddKind.task),
        child: const Icon(Icons.add_rounded),
      ),
      body: mainCategories.isEmpty
          ? const Center(child: Text('No categories yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: mainCategories.length,
              itemBuilder: (context, index) {
                final category = mainCategories[index];
                final subIds =
                    categoryProvider.subcategoriesOf(category.id).map((c) => c.id).toSet();
                final count = taskProvider.byCategory(category.id).length +
                    taskProvider.tasks.where((t) => subIds.contains(t.categoryId)).length;
                return CategoryCard(
                  category: category,
                  noteCount: count,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(categoryId: category.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
