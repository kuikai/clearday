import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/app_data.dart';
import '../models/task_group.dart';
import '../providers/tasks_provider.dart';
import '../screens/paywall/paywall_screen.dart';

/// One-line add for a task due today. The full editor stays for notes and repeat.
class QuickAddBar extends ConsumerStatefulWidget {
  const QuickAddBar({super.key});

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final TextEditingController _title = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasTitle = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    final hasTitle = _title.text.trim().isNotEmpty;
    if (hasTitle == _hasTitle) {
      return;
    }
    setState(() => _hasTitle = hasTitle);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final groups = data.groupsForPicker();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _titleField()),
                const SizedBox(width: 4),
                IconButton.filled(
                  tooltip: 'Add task',
                  onPressed: _hasTitle && !_saving ? _submit : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (groups.length > 1)
              _groupPicker(data, groups, muted)
            else if (groups.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text('Due today · ${groups.first.name}', style: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _titleField() {
    return TextField(
      controller: _title,
      focusNode: _focus,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        hintText: 'Add for today',
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _groupPicker(AppData data, List<TaskGroup> groups, TextStyle? muted) {
    final selectedId = _selectedGroupId(data, groups);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Due today', style: muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final group in groups)
                DropdownMenuItem(
                  value: group.id,
                  child: Text(
                    data.groupPath(group.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              ref.read(appDataProvider.notifier).selectGroup(value);
            },
          ),
        ),
      ],
    );
  }

  String _selectedGroupId(AppData data, List<TaskGroup> groups) {
    final preferred = data.preferredGroupId;
    if (preferred != null && groups.any((group) => group.id == preferred)) {
      return preferred;
    }
    return groups.first.id;
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) {
      return;
    }
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddTask) {
      if (mounted) {
        await showPaywall(context, reason: PaywallReason.tasks);
      }
      return;
    }

    setState(() => _saving = true);
    final groupId = await _groupIdForAdd(notifier);
    if (!mounted || groupId == null) {
      return;
    }
    final beforeCount = ref.read(appDataProvider).tasks.length;
    final result = await notifier.quickAddTask(title: title, groupId: groupId);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (result == SaveTaskResult.blockedByTaskLimit) {
      await showPaywall(context, reason: PaywallReason.tasks);
      return;
    }
    if (ref.read(appDataProvider).tasks.length == beforeCount) {
      return;
    }
    _title.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
  }

  Future<String?> _groupIdForAdd(AppDataNotifier notifier) async {
    var data = ref.read(appDataProvider);
    if (data.groups.isEmpty) {
      if (!notifier.canAddGroup) {
        setState(() => _saving = false);
        await showPaywall(context, reason: PaywallReason.groups);
        return null;
      }
      await notifier.addGroup(AppConstants.defaultGroupName);
      if (!mounted) {
        return null;
      }
      data = ref.read(appDataProvider);
    }
    final groups = data.groupsForPicker();
    if (groups.isEmpty) {
      setState(() => _saving = false);
      return null;
    }
    return _selectedGroupId(data, groups);
  }
}
