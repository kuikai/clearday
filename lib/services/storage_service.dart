import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../models/task_group.dart';

/// Persists app data, settings, and cached Pro status locally.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  static const _dataKey = 'clearday_data';
  static const _settingsKey = 'clearday_settings';
  static const _isProKey = 'clearday_is_pro';
  static const _proRefreshedAtKey = 'clearday_pro_refreshed_at';

  AppData loadAppData() {
    final raw = _prefs.getString(_dataKey);
    if (raw == null || raw.isEmpty) {
      return seedAppData();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppData.fromJson(decoded);
    } catch (_) {
      return seedAppData();
    }
  }

  Future<void> saveAppData(AppData data) async {
    await _prefs.setString(_dataKey, jsonEncode(data.toJson()));
  }

  AppData seedAppData() {
    final now = DateTime.now();
    final home = TaskGroup(
      id: _uuid.v4(),
      name: AppConstants.defaultGroupName,
      createdAt: now,
    );
    return AppData(
      groups: [home],
      tasks: const [],
      selectedGroupId: home.id,
    );
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return const AppSettings();
    }
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  bool loadIsPro() => _prefs.getBool(_isProKey) ?? false;

  DateTime? loadProRefreshedAt() {
    final raw = _prefs.getString(_proRefreshedAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> saveProStatus({
    required bool isPro,
    required DateTime refreshedAt,
  }) async {
    await Future.wait([
      _prefs.setBool(_isProKey, isPro),
      _prefs.setString(_proRefreshedAtKey, refreshedAt.toIso8601String()),
    ]);
  }
}
