import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/note_task.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../utils/priority_engine.dart';
import '../widgets/note_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'note_edit_screen.dart';
import 'pomodoro_screen.dart';

enum _Mood { normal, urgent, lazy, random, movie }

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  static const _prefsKey = 'available_minutes_today';
  int _availableMinutes = 240;
  bool _loadedPrefs = false;
  late final TextEditingController _minutesController;
  _Mood _mood = _Mood.normal;
  NoteTask? _randomPick;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _availableMinutes = prefs.getInt(_prefsKey) ?? 240;
      _minutesController.text = _availableMinutes.toString();
      _loadedPrefs = true;
    });
  }

  Future<void> _saveMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, minutes);
    if (!mounted) return;
    setState(() => _availableMinutes = minutes);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _pickRandom(List<NoteTask> pool) {
    if (pool.isEmpty) {
      setState(() => _randomPick = null);
      return;
    }
    setState(() => _randomPick = pool[Random().nextInt(pool.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskProvider = context.watch<NoteTaskProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();

    if (!_loadedPrefs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allPending = taskProvider.pendingTodos;

    List<NoteTask> poolForMood;
    switch (_mood) {
      case _Mood.urgent:
        poolForMood = allPending.where((t) => t.isUrgent).toList();
        break;
      case _Mood.lazy:
        poolForMood = allPending
            .where((t) => t.durationMinutes == null || t.durationMinutes! <= 15)
            .toList();
        break;
      default:
        poolForMood = allPending;
    }

    final plan = buildDailyPlan(
      pendingTodos: poolForMood,
      tags: tagProvider.tags,
      availableMinutes: _availableMinutes,
    );

    final remaining = _availableMinutes - plan.minutesUsed;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddSheet(context, initialKind: QuickAddKind.task),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.todayMoodPlanned),
                selected: _mood == _Mood.normal,
                onSelected: (_) => setState(() => _mood = _Mood.normal),
              ),
              ChoiceChip(
                label: Text(l10n.todayMoodUrgent),
                selected: _mood == _Mood.urgent,
                onSelected: (_) => setState(() => _mood = _Mood.urgent),
              ),
              ChoiceChip(
                label: Text(l10n.todayMoodLazy),
                selected: _mood == _Mood.lazy,
                onSelected: (_) => setState(() => _mood = _Mood.lazy),
              ),
              ChoiceChip(
                label: Text(l10n.todayMoodRandom),
                selected: _mood == _Mood.random,
                onSelected: (_) {
                  setState(() => _mood = _Mood.random);
                  _pickRandom(allPending);
                },
              ),
              ChoiceChip(
                label: Text(l10n.todayMoodMovie),
                selected: _mood == _Mood.movie,
                onSelected: (_) => setState(() => _mood = _Mood.movie),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mood == _Mood.movie) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.local_movies_rounded, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      l10n.todayMovieCard,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_mood == _Mood.random) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.todayHowAboutThis, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_randomPick == null)
                      Text(l10n.todayNothingPending)
                    else
                      NoteTaskCard(
                        task: _randomPick!,
                        priorityTag: tagProvider.byId(_randomPick!.priorityTagId),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoteEditScreen(existing: _randomPick)),
                        ),
                        onToggleDone: () => taskProvider.toggleDone(_randomPick!),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickRandom(allPending),
                      icon: const Icon(Icons.casino_rounded),
                      label: Text(l10n.todayPickAnother),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.todayTimeAvailable)),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onSubmitted: (v) {
                          final parsed = int.tryParse(v.trim());
                          if (parsed != null && parsed >= 0) _saveMinutes(parsed);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded),
                      onPressed: () {
                        final parsed = int.tryParse(_minutesController.text.trim());
                        if (parsed != null && parsed >= 0) _saveMinutes(parsed);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.todayUsedMinutes(
                plan.minutesUsed,
                _availableMinutes,
                remaining >= 0 ? remaining : 0,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.todayCanDo(plan.scheduled.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (plan.scheduled.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.todayNothingScheduled),
              )
            else
              ...plan.scheduled.map((t) => Dismissible(
                    key: ValueKey('focus_${t.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PomodoroScreen(task: t)),
                      );
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.timer_rounded),
                    ),
                    child: NoteTaskCard(
                      task: t,
                      priorityTag: tagProvider.byId(t.priorityTagId),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NoteEditScreen(existing: t)),
                      ),
                      onToggleDone: () => taskProvider.toggleDone(t),
                    ),
                  )),
            if (plan.leftover.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.todayDoesntFit(plan.leftover.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...plan.leftover.map((t) => NoteTaskCard(
                    task: t,
                    priorityTag: tagProvider.byId(t.priorityTagId),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NoteEditScreen(existing: t)),
                    ),
                    onToggleDone: () => taskProvider.toggleDone(t),
                  )),
            ],
            if (plan.noDuration.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.todayNoDurationSet(plan.noDuration.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.todaySetDurationHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...plan.noDuration.map((t) => NoteTaskCard(
                    task: t,
                    priorityTag: tagProvider.byId(t.priorityTagId),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NoteEditScreen(existing: t)),
                    ),
                    onToggleDone: () => taskProvider.toggleDone(t),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}
