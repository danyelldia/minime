import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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

/// Language-independent codes for maritalStatus, stored in the DB as
/// plain strings so switching the app's language later never breaks the
/// dropdown (only the displayed label is looked up via AppLocalizations).
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

  bool get _showsSpouseField => _maritalStatus == 'married' || _maritalStatus == 'relationship';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_people_rounded, size: 56),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_birthDate == null
                ? l10n.onboardingBirthdayOptional
                : l10n.onboardingBirthdayLabel('${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}')),
            trailing: const Icon(Icons.cake_rounded),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _normalizeStatus(_maritalStatus),
            decoration: InputDecoration(
              labelText: l10n.onboardingRelationshipOptional,
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
                labelText: l10n.onboardingPartnerNameOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onboardingHasKids),
            value: _hasKids,
            onChanged: (v) => setState(() => _hasKids = v),
          ),
          if (_hasKids)
            TextField(
              controller: _kidsController,
              decoration: InputDecoration(
                labelText: l10n.onboardingKidsNamesOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onboardingHasPets),
            value: _hasPets,
            onChanged: (v) => setState(() => _hasPets = v),
          ),
          if (_hasPets)
            TextField(
              controller: _petsController,
              decoration: InputDecoration(
                labelText: l10n.onboardingPetsNamesOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _finish,
            child: Text(l10n.onboardingFinishButton),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _skip, child: Text(l10n.onboardingSkip)),
        ],
      ),
    );
  }
}
