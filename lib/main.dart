import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db/database_helper.dart';
import 'providers/bill_provider.dart';
import 'providers/category_provider.dart';
import 'providers/note_task_provider.dart';
import 'providers/priority_tag_provider.dart';
import 'screens/bills_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notes_screen.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => PriorityTagProvider()..load()),
        ChangeNotifierProvider(create: (_) => NoteTaskProvider()..load()),
        ChangeNotifierProvider(create: (_) => BillProvider()..load()),
      ],
      child: MaterialApp(
        title: 'MiniMe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}

/// Schela principala cu navigare intre cele 4 sectiuni. Dashboard, Notes & To-Do
/// si Bills sunt functionale (Faza 2 + 3); Today ramane placeholder pana la
/// Faza 4 (motor de prioritizare zilnica).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _tabs = const [
    DashboardScreen(),
    NotesScreen(),
    BillsScreen(),
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
