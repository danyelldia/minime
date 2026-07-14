import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'providers/bill_provider.dart';
import 'providers/category_provider.dart';
import 'providers/history_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/note_task_provider.dart';
import 'providers/priority_tag_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_shell.dart';
import 'screens/note_edit_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/home_widget_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/tts_alarm_service.dart';
import 'theme/app_theme.dart';

void main() {
  // Catches ANY uncaught error anywhere in the app (startup, background
  // sync, widget build, etc.) so a single failing step never takes down
  // the whole process with a native "keeps stopping" crash. Instead we
  // log it and show a friendly on-screen message with the error, so it
  // can be diagnosed from a screenshot instead of guessing blind.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    Object? startupError;
    StackTrace? startupStack;
    try {
      // initialize the local database + seed default categories/tags
      await DatabaseHelper.instance.database;
      await NotificationService.instance.initialize();
    } catch (e, st) {
      startupError = e;
      startupStack = st;
      debugPrint('Startup error: $e\n$st');
    }

    if (startupError != null) {
      runApp(_StartupErrorApp(error: startupError, stack: startupStack));
    } else {
      runApp(const MiniMeApp());
    }
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

/// Fallback UI shown if something goes wrong before the app can even
/// start (database init, notification setup, etc.) instead of crashing
/// with no explanation. Lets the user retry, and shows enough detail to
/// diagnose the real cause from a screenshot.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, this.stack});

  final Object? error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('MiniMe - startup error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MiniMe hit a problem while starting up. Please screenshot '
                'this and send it back so it can be fixed.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText('$error\n\n${stack ?? ''}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) => MaterialApp(
          title: 'MiniMe',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const _AppRoot(),
        ),
      ),
    );
  }
}

/// Decides whether to show the first-run onboarding flow or jump
/// straight into the app, keeps the home screen widget / location
/// reminders in sync whenever the app is opened or resumed, and handles
/// deep-linking straight into a task's edit screen when the user taps
/// the body of a reminder notification (either a cold start, via
/// getInitialOpenTaskId, or while the app is already running, via the
/// onOpenTask stream fed by native onNewIntent).
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  bool _ready = false;
  StreamSubscription<String>? _openTaskSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openTaskSub = TtsAlarmService.instance.onOpenTask.listen(_openTask);
    _init();
  }

  Future<void> _init() async {
    try {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.load();
    } catch (e, st) {
      debugPrint('Profile load error: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _syncBackground();
    _checkInitialOpenTask();
  }

  Future<void> _checkInitialOpenTask() async {
    final taskId = await TtsAlarmService.instance.getInitialOpenTaskId();
    if (taskId != null) {
      _openTask(taskId);
    }
  }

  Future<void> _openTask(String taskId) async {
    if (!mounted) return;
    final taskProvider = context.read<NoteTaskProvider>();
    // Reload first - the task may just have been edited directly in the
    // database by a native notification action (Done/Snooze/Not Today),
    // or this may be a fresh cold start where the provider hasn't loaded
    // from disk yet.
    await taskProvider.load();
    if (!mounted) return;
    final task = taskProvider.byId(taskId);
    if (task == null) return;
    // Wait for the home screen to actually be on-screen (onboarding /
    // first frame) before pushing, otherwise Navigator.push can silently
    // no-op if called too early.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteEditScreen(existing: task)),
      );
    });
  }

  void _syncBackground() {
    final taskProvider = context.read<NoteTaskProvider>();
    // Fire-and-forget background sync - never let a widget/location
    // platform-channel failure take down the app.
    HomeWidgetService.update(taskProvider).catchError((e, st) {
      debugPrint('HomeWidgetService.update error: $e\n$st');
    });
    LocationService.instance.checkGeofences(taskProvider).catchError((e, st) {
      debugPrint('LocationService.checkGeofences error: $e\n$st');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready) {
      // Native notification action buttons (Done/Snooze/Not Today) write
      // straight to the SQLite database from Kotlin, bypassing this
      // provider entirely - reload so the UI reflects those changes as
      // soon as the user comes back to the app.
      context.read<NoteTaskProvider>().load();
      _syncBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _openTaskSub?.cancel();
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
