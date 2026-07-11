import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import 'home_shell.dart';

/// First-run "get to know you" screen. Framed like a personal assistant
/// introducing itself and asking a few friendly questions, so the app
/// feels like it's building a relationship with the user rather than
/// just being configured. Everything here is optional and can be edited
/// later from Settings > Profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _spouseController = TextEditingController();
  final _kidsController = TextEditingController();
  final _petsController = TextEditingController();

  DateTime? _birthDate;
  String? _maritalStatus;
  bool _hasKids = false;
  bool _hasPets = false;

  @override
  void dispose() {
    _nameController.dispose();
    _spouseController.dispose();
    _kidsController.dispose();
    _petsController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      maritalStatus: _maritalStatus,
      spouseName: _spouseController.text.trim().isEmpty ? null : _spouseController.text.trim(),
      hasKids: _hasKids,
      kidsNames: _kidsController.text.trim().isEmpty ? null : _kidsController.text.trim(),
      hasPets: _hasPets,
      petsNames: _petsController.text.trim().isEmpty ? null : _petsController.text.trim(),
      onboardingDone: true,
    );
    await context.read<ProfileProvider>().saveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _skip() async {
    await context.read<ProfileProvider>().saveProfile(
          const UserProfile(onboardingDone: true),
        );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  final _statusOptions = const [
    'Single',
    'In a relationship',
    'Married',
    'It\'s complicated',
    'Prefer not to say',
  ];

  bool get _showsSpouseField =>
      _maritalStatus == 'Married' || _maritalStatus == 'In a relationship';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi, nice to meet you'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_people_rounded, size: 56),
          const SizedBox(height: 12),
          Text(
            "I'm MiniMe, your personal organizer. Tell me a bit about "
            "yourself so I can feel a little more like your assistant "
            "and less like a stranger. Everything here is optional and "
            "stays only on this phone.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'What should I call you?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_birthDate == null
                ? 'Birthday (optional)'
                : 'Birthday: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
            trailing: const Icon(Icons.cake_rounded),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Relationship status (optional)',
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
                labelText: "Partner's name (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Do you have kids?'),
            value: _hasKids,
            onChanged: (v) => setState(() => _hasKids = v),
          ),
          if (_hasKids)
            TextField(
              controller: _kidsController,
              decoration: const InputDecoration(
                labelText: "Kids' names (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Any pets?'),
            value: _hasPets,
            onChanged: (v) => setState(() => _hasPets = v),
          ),
          if (_hasPets)
            TextField(
              controller: _petsController,
              decoration: const InputDecoration(
                labelText: "Pets' names (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _finish,
            child: const Text("That's me, let's start"),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _skip, child: const Text('Skip for now')),
        ],
      ),
    );
  }
}
