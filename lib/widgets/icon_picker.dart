import 'package:flutter/material.dart';

import '../models/category.dart';

class IconPickerGrid extends StatelessWidget {
  final IconData? selected;
  final ValueChanged<IconData> onChanged;

  const IconPickerGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableCategoryIcons.map((icon) {
        final isSelected = selected != null && selected!.codePoint == icon.codePoint;
        return GestureDetector(
          onTap: () => onChanged(icon),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
        );
      }).toList(),
    );
  }
}
