import 'package:flutter/material.dart';

import '../services/export_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      await ExportService.exportAndShare();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Profile'),
            subtitle: const Text('What MiniMe knows about you'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Export / backup data'),
            subtitle: const Text('Save a JSON copy of everything in MiniMe'),
            onTap: () => _export(context),
          ),
        ],
      ),
    );
  }
}
