import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage, this._notifications)
      : super(_storage.loadSettings());

  final StorageService _storage;
  final NotificationService _notifications;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.saveSettings(state);
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    if (value) {
      final granted = await _notifications.requestPermission();
      state = state.copyWith(notificationsEnabled: granted);
      await _storage.saveSettings(state);
      return granted;
    }

    state = state.copyWith(notificationsEnabled: false);
    await _storage.saveSettings(state);
    return false;
  }
}
