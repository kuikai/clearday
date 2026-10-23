import 'package:clearday/core/theme/app_skin.dart';
import 'package:clearday/models/app_settings.dart';
import 'package:clearday/providers/app_providers.dart';
import 'package:clearday/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  test('older settings keep groups expanded and the Clear skin', () {
    final settings = AppSettings.fromJson({'themeMode': 'dark'});

    expect(settings.groupsExpanded, isTrue);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.skin, AppSkin.clear);
  });

  test('collapsed groups are saved and loaded', () {
    final settings = const AppSettings(groupsExpanded: false);

    expect(AppSettings.fromJson(settings.toJson()).groupsExpanded, isFalse);
  });

  test('a skin is saved and loaded', () {
    const settings = AppSettings(skin: AppSkin.ocean);

    expect(AppSettings.fromJson(settings.toJson()).skin, AppSkin.ocean);
  });

  test('an unknown skin falls back to Clear', () {
    expect(AppSettings.fromJson({'skin': 'neon'}).skin, AppSkin.clear);
    expect(AppSettings.fromJson({'skin': ''}).skin, AppSkin.clear);
  });

  test('choosing a skin is saved', () async {
    final container = await createTestContainer();

    await container.read(settingsProvider.notifier).setSkin(AppSkin.dusk);

    expect(container.read(settingsProvider).skin, AppSkin.dusk);
    expect(
      container.read(storageServiceProvider).loadSettings().skin,
      AppSkin.dusk,
    );
  });
}
