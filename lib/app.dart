import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';

class ClearDayApp extends ConsumerWidget {
  const ClearDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsProvider.select((settings) => settings.themeMode),
    );
    final skin = ref.watch(
      settingsProvider.select((settings) => settings.skin),
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(skin: skin),
      darkTheme: AppTheme.dark(skin: skin),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
