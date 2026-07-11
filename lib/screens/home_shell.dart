import 'package:flutter/material.dart';

import 'bills_screen.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import 'today_screen.dart';

/// Main shell with navigation between the 4 sections: Dashboard,
/// Notes & To-Do, Bills, Today. History, Settings, Profile and the
/// Eisenhower Matrix are reachable from the Dashboard's app bar.
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
    TodayScreen(),
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
