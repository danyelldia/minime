import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../providers/note_task_provider.dart';
import '../widgets/category_card.dart';
import 'category_detail_screen.dart';
import 'category_edit_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();
    final mainCategories = categoryProvider.mainCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes & To-Do')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryEditScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: mainCategories.isEmpty
          ? const Center(child: Text('Nicio categorie inca'))
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
