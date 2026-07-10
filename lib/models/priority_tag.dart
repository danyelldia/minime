import 'package:flutter/material.dart';

enum PriorityTagType { thisWeek, thisMonth, nextMonth, thisYear, custom }

/// Tag de prioritizare (this week / this month / next month / this year / custom).
/// Fiecare tag are propria culoare, folosita ca indicator vizual de urgenta.
class PriorityTag {
  final String id;
  final String label;
  final Color color;
  final PriorityTagType type;

  const PriorityTag({
    required this.id,
    required this.label,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'color': color.value,
        'type': type.name,
      };

  factory PriorityTag.fromMap(Map<String, dynamic> map) => PriorityTag(
        id: map['id'] as String,
        label: map['label'] as String,
        color: Color(map['color'] as int),
        type: PriorityTagType.values.byName(map['type'] as String),
      );
}

/// Tag-uri implicite. Userul poate adauga tag-uri custom (nume + culoare).
List<PriorityTag> defaultPriorityTags() => const [
      PriorityTag(
        id: 'this_week',
        label: 'This Week',
        color: Color(0xFFE53935), // rosu - urgent
        type: PriorityTagType.thisWeek,
      ),
      PriorityTag(
        id: 'this_month',
        label: 'This Month',
        color: Color(0xFFFB8C00), // portocaliu
        type: PriorityTagType.thisMonth,
      ),
      PriorityTag(
        id: 'next_month',
        label: 'Next Month',
        color: Color(0xFF43A047), // verde
        type: PriorityTagType.nextMonth,
      ),
      PriorityTag(
        id: 'this_year',
        label: 'This Year',
        color: Color(0xFF3949AB), // albastru
        type: PriorityTagType.thisYear,
      ),
    ];
