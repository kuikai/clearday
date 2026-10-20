import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/today_widget_data.dart';
import '../models/app_data.dart';

const _channel = MethodChannel('clearday/today_widget');

/// Writes the widget snapshot, then asks Android to redraw it.
Future<void> publishTodayWidget(SharedPreferences prefs, AppData data) async {
  final tasks = todayWidgetTasks(data, DateTime.now());
  await prefs.setString(todayWidgetPrefsKey, encodeTodayWidgetTasks(tasks));
  await refreshTodayWidget();
}

Future<void> refreshTodayWidget() async {
  try {
    await _channel.invokeMethod<void>('update');
  } catch (_) {
    // Android has the widget channel. Tests and other platforms skip it.
  }
}
