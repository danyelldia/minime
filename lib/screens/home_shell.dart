import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'bills_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import 'today_screen.dart';

/// Main shell with navigation between the 5 sections: Dashboard,
/// Notes & To-Do, Bills, Calendar, Today. History, Settings, Profile and
/// the Eisenhower Matrix are reachable from the Dashboard's app bar.
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
    CalendarScreen(),
    TodayScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: l10n.navDashboard),
          NavigationDestination(icon: const Icon(Icons.checklist_rounded), label: l10n.navNotes),
          NavigationDestination(icon: const Icon(Icons.receipt_long_rounded), label: l10n.navBills),
          NavigationDestination(icon: const Icon(Icons.calendar_month_rounded), label: l10n.navCalendar),
          NavigationDestination(icon: const Icon(Icons.today_rounded), label: l10n.navToday),
        ],
      ),
    );
  }
}
