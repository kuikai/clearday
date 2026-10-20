import 'package:clearday/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('older settings keep groups expanded', () {
    final settings = AppSettings.fromJson({'themeMode': 'dark'});

    expect(settings.groupsExpanded, isTrue);
    expect(settings.themeMode, ThemeMode.dark);
  });

  test('collapsed groups are saved and loaded', () {
    final settings = const AppSettings(groupsExpanded: false);

    expect(
      AppSettings.fromJson(settings.toJson()).groupsExpanded,
      isFalse,
    );
  });
}
