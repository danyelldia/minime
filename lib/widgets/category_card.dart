import 'package:flutter/material.dart';

import '../models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final int noteCount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.noteCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withOpacity(0.15),
                foregroundColor: category.color,
                child: Icon(category.icon),
              ),
              const SizedBox(height: 12),
              Text(category.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$noteCount notes/to-dos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
