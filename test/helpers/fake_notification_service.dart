import 'package:clearday/models/task.dart';
import 'package:clearday/services/notification_service.dart';

/// No-op notifications so unit tests never touch plugins.
class FakeNotificationService extends NotificationService {
  final List<List<Task>> syncedBatches = [];
  int permissionRequests = 0;

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return true;
  }

  @override
  Future<void> syncTaskReminders(List<Task> tasks) async {
    syncedBatches.add(List<Task>.from(tasks));
  }
}
