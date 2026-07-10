import 'package:flutter/material.dart';

/// Paleta de culori disponibila atat pentru culoarea unei categorii,
/// cat si pentru culoarea de urgenta a unei notite/to-do.
const List<Color> presetColors = [
  Color(0xFFE53935), // rosu
  Color(0xFFFB8C00), // portocaliu
  Color(0xFFFDD835), // galben
  Color(0xFF43A047), // verde
  Color(0xFF00897B), // teal
  Color(0xFF1E88E5), // albastru
  Color(0xFF3949AB), // indigo
  Color(0xFF8E24AA), // mov
  Color(0xFFD81B60), // roz
  Color(0xFF6D4C41), // maro
  Color(0xFF546E7A), // gri-albastrui
  Color(0xFF212121), // negru
];

class ColorSwatchPicker extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color> onChanged;

  const ColorSwatchPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: presetColors.map((color) {
        final isSelected = selected != null && selected!.value == color.value;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black87, width: 3) : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }
}
