import 'package:geolocator/geolocator.dart';

import '../models/note_task.dart';
import '../providers/note_task_provider.dart';
import 'notification_service.dart';

/// Location-based reminders. This checks the device's current position
/// against each to-do's saved location whenever the app is opened or
/// resumed (and on a periodic timer while it's in the foreground) and
/// fires a local notification when the user is within range.
///
/// Note: this is a foreground check, not a true OS-level background
/// geofence - Android's background location restrictions make a real
/// always-on geofence a much heavier (and battery-hungrier) addition.
/// This version is reliable while MiniMe is open or freshly resumed,
/// which covers "I just arrived somewhere and opened my phone" - the
/// most common real-world case.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  String _todayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Checks all to-dos with a saved location against the current position
  /// and fires a notification for any that are within range and haven't
  /// already triggered today.
  Future<void> checkGeofences(NoteTaskProvider provider) async {
    final tasksWithLocation = provider.tasksWithLocation;
    if (tasksWithLocation.isEmpty) return;

    final position = await currentPosition();
    if (position == null) return;

    final todayKey = _todayKey(DateTime.now());

    for (final task in tasksWithLocation) {
      if (task.locationLastTriggeredDate == todayKey) continue;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        task.locationLat!,
        task.locationLng!,
      );
      final radius = task.locationRadius ?? 200;
      if (distance <= radius) {
        await NotificationService.instance.showLocationReminder(task);
        await provider.markLocationTriggered(task.id, todayKey);
      }
    }
  }
}
