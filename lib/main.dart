import 'package:flutter/material.dart';

import 'db/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initializeaza baza de date locala + seed-uieste categoriile/tag-urile implicite
  await DatabaseHelper.instance.database;
  runApp(const MiniMeApp());
}

class MiniMeApp extends StatelessWidget {
  const MiniMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}

/// Schela principala cu navigare intre cele 4 sectiuni.
/// Continutul real (Dashboard, Notes/To-Do, Bills, Today) se adauga
/// in fazele urmatoare - acum e doar scheletul care confirma ca
/// proiectul si modelul de date se compileaza corect.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _tabs = const [
    _PlaceholderTab(title: 'Dashboard', icon: Icons.dashboard_rounded),
    _PlaceholderTab(title: 'Notes & To-Do', icon: Icons.checklist_rounded),
    _PlaceholderTab(title: 'Bills', icon: Icons.receipt_long_rounded),
    _PlaceholderTab(title: 'Today', icon: Icons.today_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.today_rounded), label: 'Today'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Vine in urmatoarea faza'),
          ],
        ),
      ),
    );
  }
}
