import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db/database_helper.dart';
import 'providers/bill_provider.dart';
import 'providers/category_provider.dart';
import 'providers/history_provider.dart';
import 'providers/note_task_provider.dart';
import 'providers/priority_tag_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/home_widget_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize the local database + seed default categories/tags
  await DatabaseHelper.instance.database;
  await NotificationService.instance.initialize();
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
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
      ],
      child: MaterialApp(
        title: 'MiniMe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Decides whether to show the first-run onboarding flow or jump
/// straight into the app, and keeps the home screen widget / location
/// reminders in sync whenever the app is opened or resumed.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.load();
    if (!mounted) return;
    setState(() => _ready = true);
    _syncBackground();
  }

  void _syncBackground() {
    final taskProvider = context.read<NoteTaskProvider>();
    HomeWidgetService.update(taskProvider);
    LocationService.instance.checkGeofences(taskProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready) {
      _syncBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = context.watch<ProfileProvider>().profile;
    return profile.onboardingDone ? const HomeShell() : const OnboardingScreen();
  }
}
