import 'dart:async';

import 'package:flutter/material.dart';

import '../models/note_task.dart';
import '../services/tts_service.dart';

/// Focus timer linked to a task's estimated duration. Defaults to the
/// task's durationMinutes if it has one (converted to minutes regardless
/// of the display unit), otherwise the classic 25-minute Pomodoro.
class PomodoroScreen extends StatefulWidget {
  final NoteTask? task;
  const PomodoroScreen({super.key, this.task});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final minutes = widget.task?.durationMinutes ?? 25;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });
        TtsService.instance.speak('Time is up. Focus session complete.');
        _showDoneDialog();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _running = false;
    });
  }

  void _showDoneDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Focus session complete'),
        content: Text(widget.task != null
            ? 'Nice work on "${widget.task!.title}".'
            : 'Nice work! Take a short break.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : 1 - (_remainingSeconds / _totalSeconds);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus timer')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.task != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.task!.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                    ),
                  ),
                  Text(_format(_remainingSeconds), style: const TextStyle(fontSize: 40)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  iconSize: 36,
                  onPressed: _reset,
                  icon: const Icon(Icons.replay_rounded),
                ),
                const SizedBox(width: 20),
                IconButton.filled(
                  iconSize: 44,
                  onPressed: _running ? _pause : _start,
                  icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
