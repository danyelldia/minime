import 'package:flutter/material.dart';

/// O categorie sau subcategorie (Home, Work, Personal + orice adauga userul).
/// parentId == null -> categorie principala. altfel -> subcategorie.
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
  });

  bool get isMainCategory => parentId == null;

  Category copyWith({
    String? name,
    IconData? icon,
    Color? color,
    String? parentId,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon.codePoint,
        'color': color.value,
        'parentId': parentId,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(map['color'] as int),
        parentId: map['parentId'] as String?,
      );
}

/// Categoriile principale implicite. Userul poate adauga oricate altele
/// (ex. o a 4-a categorie mare) sau subcategorii sub cele existente
/// (ex. Home -> Electricity / Dormitor 1 / Proiect bucatarie).
List<Category> defaultMainCategories() => [
      const Category(
        id: 'home',
        name: 'Home',
        icon: Icons.home_rounded,
        color: Color(0xFF4CAF50),
      ),
      const Category(
        id: 'work',
        name: 'Work',
        icon: Icons.work_rounded,
        color: Color(0xFF2196F3),
      ),
      const Category(
        id: 'personal',
        name: 'Personal',
        icon: Icons.person_rounded,
        color: Color(0xFF9C27B0),
      ),
    ];

/// Id-ul special al categoriei "Quick Notes" - unde ajung implicit
/// notitele scrise rapid din Dashboard. Este o categorie reala (userul o
/// poate alege si din dropdown-ul de categorie ca sa mute o notita in
/// alta parte), dar e ascunsa din grila celor 3 categorii mari de pe
/// ecranul Notes, ca sa nu para "a 4-a categorie mare".
const String quickNotesCategoryId = 'quick_notes';

/// Categoria speciala pentru notite rapide, adaugata automat la prima
/// rulare (sau la upgrade pentru userii existenti).
Category quickNotesCategory() => const Category(
      id: quickNotesCategoryId,
      name: 'Quick Notes',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFFA000),
    );

/// Iconite disponibile la crearea unei categorii/subcategorii noi.
const List<IconData> availableCategoryIcons = [
  Icons.home_rounded,
  Icons.work_rounded,
  Icons.person_rounded,
  Icons.bolt_rounded,
  Icons.bed_rounded,
  Icons.kitchen_rounded,
  Icons.build_rounded,
  Icons.school_rounded,
  Icons.fitness_center_rounded,
  Icons.favorite_rounded,
  Icons.directions_car_rounded,
  Icons.pets_rounded,
  Icons.shopping_cart_rounded,
  Icons.laptop_mac_rounded,
  Icons.groups_rounded,
  Icons.star_rounded,
];
