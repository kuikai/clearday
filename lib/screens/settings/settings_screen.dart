import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/pro_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/collapsible_section.dart';
import '../../widgets/restore_purchase_button.dart';
import '../../widgets/skin_picker.dart';
import '../../widgets/upgrade_pro_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPro = ref.watch(proProvider.select((status) => status.isPro));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _AppearanceCard(),
          const SizedBox(height: 16),
          CollapsibleSection(
            title: 'App Skin',
            collapsedSubtitle: 'Current: ${settings.skin.label}',
            expandedSubtitle:
                'Try a different color. Changes apply right away.',
            child: SkinPicker(
              selected: settings.skin,
              onSelected: ref.read(settingsProvider.notifier).setSkin,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Reminders'),
              subtitle: const Text('Local notifications when a task is due'),
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
                              'Pro unlocks unlimited use, repeating chores, '
                              'and custom reminder times.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
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

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
            const SizedBox(height: 12),
            const _ThemeModeButton(),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeButton extends ConsumerWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      settingsProvider.select((settings) => settings.themeMode),
    );

    return SegmentedButton<ThemeMode>(
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
      selected: {mode},
      onSelectionChanged: (value) {
        ref.read(settingsProvider.notifier).setThemeMode(value.first);
      },
    );
  }
}
