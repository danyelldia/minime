import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

const List<String> _statusCodes = [
  'single',
  'relationship',
  'married',
  'complicated',
  'prefer_not_to_say',
];

String _statusLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'single':
      return l10n.statusSingle;
    case 'relationship':
      return l10n.statusRelationship;
    case 'married':
      return l10n.statusMarried;
    case 'complicated':
      return l10n.statusComplicated;
    case 'prefer_not_to_say':
      return l10n.statusPreferNotToSay;
    default:
      return code;
  }
}

/// Old app versions saved the literal English label as maritalStatus.
/// Normalize any of that (or an already-valid code) into a code, so an
/// existing profile never crashes the dropdown after this update.
String? _normalizeStatus(String? raw) {
  if (raw == null) return null;
  if (_statusCodes.contains(raw)) return raw;
  switch (raw.toLowerCase()) {
    case 'single':
      return 'single';
    case 'in a relationship':
      return 'relationship';
    case 'married':
      return 'married';
    case "it's complicated":
      return 'complicated';
    case 'prefer not to say':
      return 'prefer_not_to_say';
    default:
      return null;
  }
}

/// Shows and edits the structured profile collected during onboarding,
/// plus the free-form list of facts MiniMe remembers about the user
/// ("Add to Profile" - things like "I like pizza" or "My mother's name
/// is Maria").
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _spouseController;
  late TextEditingController _kidsController;
  late TextEditingController _petsController;
  final _factController = TextEditingController();

  DateTime? _birthDate;
  String? _maritalStatus;
  bool _hasKids = false;
  bool _hasPets = false;
  bool _initialized = false;

  void _loadFrom(UserProfile p) {
    _nameController = TextEditingController(text: p.name);
    _spouseController = TextEditingController(text: p.spouseName ?? '');
    _kidsController = TextEditingController(text: p.kidsNames ?? '');
    _petsController = TextEditingController(text: p.petsNames ?? '');
    _birthDate = p.birthDate;
    _maritalStatus = _normalizeStatus(p.maritalStatus);
    _hasKids = p.hasKids;
    _hasPets = p.hasPets;
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _spouseController.dispose();
      _kidsController.dispose();
      _petsController.dispose();
    }
    _factController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1920, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProfileProvider>();
    final updated = provider.profile.copyWith(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      maritalStatus: _maritalStatus,
      spouseName: _spouseController.text.trim().isEmpty ? null : _spouseController.text.trim(),
      hasKids: _hasKids,
      kidsNames: _kidsController.text.trim().isEmpty ? null : _kidsController.text.trim(),
      hasPets: _hasPets,
      petsNames: _petsController.text.trim().isEmpty ? null : _petsController.text.trim(),
    );
    await provider.saveProfile(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSavedSnack)),
      );
    }
  }

  Future<void> _addFact() async {
    final text = _factController.text.trim();
    if (text.isEmpty) return;
    await context.read<ProfileProvider>().addFact(text);
    _factController.clear();
  }

  bool get _showsSpouseField => _maritalStatus == 'married' || _maritalStatus == 'relationship';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileProvider = context.watch<ProfileProvider>();
    if (!_initialized) _loadFrom(profileProvider.profile);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.profileName, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_birthDate == null
                ? l10n.profileBirthday
                : l10n.profileBirthdayLabel('${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}')),
            trailing: const Icon(Icons.cake_rounded),
            onTap: _pickBirthDate,
          ),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: InputDecoration(
              labelText: l10n.profileRelationship,
              border: const OutlineInputBorder(),
            ),
            items: _statusCodes
                .map((code) => DropdownMenuItem(value: code, child: Text(_statusLabel(l10n, code))))
                .toList(),
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
          if (_showsSpouseField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _spouseController,
              decoration: InputDecoration(
                labelText: l10n.profilePartnerName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.profileKids),
            value: _hasKids,
            onChanged: (v) => setState(() => _hasKids = v),
          ),
          if (_hasKids)
            TextField(
              controller: _kidsController,
              decoration: InputDecoration(
                labelText: l10n.profileKidsNames,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.profilePets),
            value: _hasPets,
            onChanged: (v) => setState(() => _hasPets = v),
          ),
          if (_hasPets)
            TextField(
              controller: _petsController,
              decoration: InputDecoration(
                labelText: l10n.profilePetsNames,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(l10n.profileSaveButton)),
          const Divider(height: 48),
          Text(l10n.profileFactsSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.profileFactsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _factController,
                  decoration: InputDecoration(
                    hintText: l10n.profileAddToProfileHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addFact(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _addFact, icon: const Icon(Icons.add_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          ...profileProvider.facts.map((fact) => Card(
                child: ListTile(
                  title: Text(fact.text),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => context.read<ProfileProvider>().deleteFact(fact.id),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
