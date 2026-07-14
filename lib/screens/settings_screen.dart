import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ExportService.exportAndShare();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsExportFailed(e.toString()))),
        );
      }
    }
  }

  String _languageLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'ro':
        return l10n.langRomanian;
      case 'es':
        return l10n.langSpanish;
      case 'fr':
        return l10n.langFrench;
      case 'ru':
        return l10n.langRussian;
      case 'de':
        return l10n.langGerman;
      case 'it':
        return l10n.langItalian;
      case 'pt':
        return l10n.langPortuguese;
      case 'pl':
        return l10n.langPolish;
      case 'en':
      default:
        return l10n.langEnglish;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsThemeSection,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsLanguageSection,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: LocaleProvider.supportedCodes.map((code) {
                final selected = localeProvider.languageCode == code;
                return ChoiceChip(
                  label: Text(_languageLabel(l10n, code)),
                  selected: selected,
                  onSelected: (_) => localeProvider.setLocale(code),
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Divider(height: 1),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(l10n.settingsProfileTitle),
            subtitle: Text(l10n.settingsProfileSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: Text(l10n.settingsExportTitle),
            subtitle: Text(l10n.settingsExportSubtitle),
            onTap: () => _export(context),
          ),
        ],
      ),
    );
  }
}
