import 'package:home_widget/home_widget.dart';

import '../providers/note_task_provider.dart';

/// Pushes a small summary (how many to-dos are pending today, and the
/// next one up) to the Android home screen widget. Called on app start,
/// resume, and whenever the task list changes meaningfully.
class HomeWidgetService {
  HomeWidgetService._();

  // Must match the receiver class the build workflow generates into the
  // app's actual package (see .github/workflows/build-apk.yml).
  static const String _qualifiedProviderName =
      'com.danyell.minime.minime.TodayWidgetProvider';

  static Future<void> update(NoteTaskProvider provider) async {
    final pending = provider.pendingTodos;
    final next = pending.isEmpty ? null : pending.first;

    await HomeWidget.saveWidgetData<int>('minime_pending_count', pending.length);
    await HomeWidget.saveWidgetData<String>(
      'minime_next_title',
      next?.title ?? 'Nothing pending - nice!',
    );
    await HomeWidget.updateWidget(
      name: 'TodayWidgetProvider',
      qualifiedAndroidName: _qualifiedProviderName,
    );
  }
}
