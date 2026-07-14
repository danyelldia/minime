import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: AppTheme.labels.entries.map((entry) {
                final selected = themeProvider.themeName == entry.key;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => themeProvider.setTheme(entry.key),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.swatch[entry.key],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(entry.value, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Divider(height: 1),
          ),
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
