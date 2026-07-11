/// The user's personal profile - collected during onboarding and editable
/// later from Settings > Profile. Everything is optional; MiniMe never
/// sends this data anywhere, it stays in the local database.
class UserProfile {
  final String name;
  final DateTime? birthDate;
  final String? maritalStatus; // 'single' | 'married' | 'in a relationship' | 'other'
  final String? spouseName;
  final bool hasKids;
  final String? kidsNames;
  final bool hasPets;
  final String? petsNames;
  final bool onboardingDone;

  const UserProfile({
    this.name = '',
    this.birthDate,
    this.maritalStatus,
    this.spouseName,
    this.hasKids = false,
    this.kidsNames,
    this.hasPets = false,
    this.petsNames,
    this.onboardingDone = false,
  });

  UserProfile copyWith({
    String? name,
    DateTime? birthDate,
    String? maritalStatus,
    String? spouseName,
    bool? hasKids,
    String? kidsNames,
    bool? hasPets,
    String? petsNames,
    bool? onboardingDone,
  }) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      spouseName: spouseName ?? this.spouseName,
      hasKids: hasKids ?? this.hasKids,
      kidsNames: kidsNames ?? this.kidsNames,
      hasPets: hasPets ?? this.hasPets,
      petsNames: petsNames ?? this.petsNames,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 'me',
        'name': name,
        'birthDate': birthDate?.toIso8601String(),
        'maritalStatus': maritalStatus,
        'spouseName': spouseName,
        'hasKids': hasKids ? 1 : 0,
        'kidsNames': kidsNames,
        'hasPets': hasPets ? 1 : 0,
        'petsNames': petsNames,
        'onboardingDone': onboardingDone ? 1 : 0,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] as String? ?? '',
        birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate'] as String) : null,
        maritalStatus: map['maritalStatus'] as String?,
        spouseName: map['spouseName'] as String?,
        hasKids: ((map['hasKids'] as int?) ?? 0) == 1,
        kidsNames: map['kidsNames'] as String?,
        hasPets: ((map['hasPets'] as int?) ?? 0) == 1,
        petsNames: map['petsNames'] as String?,
        onboardingDone: ((map['onboardingDone'] as int?) ?? 0) == 1,
      );
}

/// A free-form fact the user chose to have MiniMe remember about them,
/// e.g. "I like pizza" or "My mother's name is Maria". Added from
/// Settings > Profile > Add to Profile.
class ProfileFact {
  final String id;
  final String text;
  final DateTime createdAt;

  const ProfileFact({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProfileFact.fromMap(Map<String, dynamic> map) => ProfileFact(
        id: map['id'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
