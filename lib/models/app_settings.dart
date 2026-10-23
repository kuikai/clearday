import 'package:flutter/material.dart';

import '../core/theme/app_skin.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.skin = AppSkin.clear,
    this.notificationsEnabled = true,
    this.groupsExpanded = true,
  });

  final ThemeMode themeMode;
  final AppSkin skin;
  final bool notificationsEnabled;
  final bool groupsExpanded;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppSkin? skin,
    bool? notificationsEnabled,
    bool? groupsExpanded,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      skin: skin ?? this.skin,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      groupsExpanded: groupsExpanded ?? this.groupsExpanded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'skin': skin.name,
      'notificationsEnabled': notificationsEnabled,
      'groupsExpanded': groupsExpanded,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (value) => value.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      skin: AppSkin.fromName(json['skin']),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      groupsExpanded: json['groupsExpanded'] as bool? ?? true,
    );
  }
}
