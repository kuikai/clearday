import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/pro_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/restore_purchase_button.dart';
import '../../widgets/upgrade_pro_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPro = ref.watch(proProvider.select((status) => status.isPro));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(value.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Reminders'),
              subtitle: const Text(
                'Local notifications when a task is due',
              ),
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                final granted = await ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(value);
                await ref.read(appDataProvider.notifier).resyncReminders();
                if (!granted && value && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification permission was denied. '
                        'You can enable it in system settings.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ClearDay Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? 'Pro is unlocked. Unlimited tasks, groups, '
                            'recurring chores, and custom reminders.'
                        : 'Free: ${AppConstants.freeActiveTaskLimit} active '
                            'tasks, ${AppConstants.freeGroupLimit} groups, '
                            'and ${AppConstants.freeSubgroupLimit} subgroups. '
                            'Unlock Pro for unlimited use.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isPro)
                    const Text('You have Pro')
                  else ...[
                    const UpgradeProButton(),
                    const RestorePurchaseButton(),
                  ],
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Unlock Pro (debug)'),
                    onTap: () {
                      ref.read(proProvider.notifier).unlockProForTesting();
                    },
                  ),
                  ListTile(
                    title: const Text('Reset Pro (debug)'),
                    onTap: () {
                      ref.read(proProvider.notifier).resetProForTesting();
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            AppConstants.appTagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
