import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

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

  final _statusOptions = const [
    'Single',
    'In a relationship',
    'Married',
    'It\'s complicated',
    'Prefer not to say',
  ];

  void _loadFrom(UserProfile p) {
    _nameController = TextEditingController(text: p.name);
    _spouseController = TextEditingController(text: p.spouseName ?? '');
    _kidsController = TextEditingController(text: p.kidsNames ?? '');
    _petsController = TextEditingController(text: p.petsNames ?? '');
    _birthDate = p.birthDate;
    _maritalStatus = p.maritalStatus;
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
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  Future<void> _addFact() async {
    final text = _factController.text.trim();
    if (text.isEmpty) return;
    await context.read<ProfileProvider>().addFact(text);
    _factController.clear();
  }

  bool get _showsSpouseField =>
      _maritalStatus == 'Married' || _maritalStatus == 'In a relationship';

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    if (!_initialized) _loadFrom(profileProvider.profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_birthDate == null
                ? 'Birthday'
                : 'Birthday: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
            trailing: const Icon(Icons.cake_rounded),
            onTap: _pickBirthDate,
          ),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Relationship status',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
          if (_showsSpouseField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _spouseController,
              decoration: const InputDecoration(
                labelText: "Partner's name",
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kids'),
            value: _hasKids,
            onChanged: (v) => setState(() => _hasKids = v),
          ),
          if (_hasKids)
            TextField(
              controller: _kidsController,
              decoration: const InputDecoration(
                labelText: "Kids' names",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pets'),
            value: _hasPets,
            onChanged: (v) => setState(() => _hasPets = v),
          ),
          if (_hasPets)
            TextField(
              controller: _petsController,
              decoration: const InputDecoration(
                labelText: "Pets' names",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save profile')),
          const Divider(height: 48),
          Text('Things I remember about you', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add short facts, like "I like pizza" or "My mother\'s name is Maria".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _factController,
                  decoration: const InputDecoration(
                    hintText: 'Add to profile...',
                    border: OutlineInputBorder(),
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
