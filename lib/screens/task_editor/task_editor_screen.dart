import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/date_utils.dart';
import '../../models/recurrence.dart';
import '../../models/task.dart';
import '../../providers/pro_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/pro_lock.dart';
import '../../widgets/task_editor_fields.dart';
import '../paywall/paywall_screen.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({
    super.key,
    required this.task,
    required this.isNew,
  });

  final Task task;
  final bool isNew;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late String _groupId;
  DateTime? _dueAt;
  bool _dueHasTime = false;
  DateTime? _reminderAt;
  Recurrence _recurrence = const Recurrence();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task.title);
    _notesController = TextEditingController(text: task.notes);
    _groupId = task.groupId;
    _dueAt = task.dueAt;
    _dueHasTime = task.dueHasTime;
    _reminderAt = task.reminderAt;
    _recurrence = task.recurrence;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proProvider.select((status) => status.isPro));
    final data = ref.watch(appDataProvider);
    final groups = data.groupsForPicker();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New task' : 'Edit task'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: groups.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Create a group first, then add tasks to it.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'What needs doing?',
                    labelText: 'Task',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add a note if you need it',
                    labelText: 'Notes',
                  ),
                ),
                const SizedBox(height: 24),
                EditorSectionCard(
                  title: 'Where',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_groupId),
                    initialValue: groups.any((group) => group.id == _groupId)
                        ? _groupId
                        : groups.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Group',
                    ),
                    items: [
                      for (final group in groups)
                        DropdownMenuItem(
                          value: group.id,
                          child: Text(data.groupPath(group.id)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _groupId = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                EditorSectionCard(
                  title: 'When',
                  child: Column(
                    children: [
                      EditorDateRow(
                        icon: Icons.event_outlined,
                        label: 'Due date',
                        value: _dueAt == null
                            ? 'None'
                            : formatDueLabel(_dueAt!, hasTime: _dueHasTime),
                        onTap: _pickDueDate,
                        onClear: _dueAt == null ? null : _clearDue,
                      ),
                      if (_dueAt != null)
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Due time'),
                          subtitle: Text(
                            _dueHasTime
                                ? DateFormat.jm().format(_dueAt!)
                                : 'All day Â· reminder at 9:00 AM',
                          ),
                          value: _dueHasTime,
                          onChanged: _toggleDueTime,
                        ),
                      ProLock(
                        locked: !isPro,
                        onLockedTap: () => showPaywall(context),
                        child: EditorDateRow(
                          icon: Icons.notifications_outlined,
                          label: 'Reminder',
                          value: _reminderLabel(isPro),
                          onTap: isPro
                              ? _pickReminder
                              : () => showPaywall(context),
                          onClear: isPro && _reminderAt != null
                              ? _clearReminder
                              : null,
                        ),
                      ),
                      if (!isPro)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Free reminders fire at the due date/time. '
                            'Pro unlocks a custom reminder.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RecurrenceCard(
                  recurrence: _recurrence,
                  enabled: isPro,
                  onLockedTap: () => showPaywall(context),
                  onChanged: (value) => setState(() => _recurrence = value),
                ),
              ],
            ),
    );
  }

  String _reminderLabel(bool isPro) {
    if (!isPro) {
      if (_dueAt == null) {
        return 'Set a due date first';
      }
      final reminder = ref.read(appDataProvider.notifier).defaultReminderFor(
            dueAt: _dueAt,
            dueHasTime: _dueHasTime,
          );
      return reminder == null ? 'None' : formatReminderLabel(reminder);
    }
    if (_reminderAt == null) {
      return 'None';
    }
    return formatReminderLabel(_reminderAt!);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final time = _dueHasTime && _dueAt != null
          ? TimeOfDay.fromDateTime(_dueAt!)
          : const TimeOfDay(hour: AppConstants.defaultReminderHour, minute: 0);
      _dueAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      if (!_dueHasTime) {
        _syncFreeReminder();
      }
    });
  }

  Future<void> _toggleDueTime(bool value) async {
    if (!value) {
      setState(() {
        _dueHasTime = false;
        if (_dueAt != null) {
          _dueAt = DateTime(_dueAt!.year, _dueAt!.month, _dueAt!.day, 9);
        }
        _syncFreeReminder();
      });
      return;
    }

    final initial = _dueAt != null
        ? TimeOfDay.fromDateTime(_dueAt!)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || _dueAt == null) {
      return;
    }
    setState(() {
      _dueHasTime = true;
      _dueAt = DateTime(
        _dueAt!.year,
        _dueAt!.month,
        _dueAt!.day,
        picked.hour,
        picked.minute,
      );
      _syncFreeReminder();
    });
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt != null
          ? TimeOfDay.fromDateTime(_reminderAt!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _clearDue() {
    setState(() {
      _dueAt = null;
      _dueHasTime = false;
      _reminderAt = null;
    });
  }

  void _clearReminder() {
    setState(() => _reminderAt = null);
  }

  void _syncFreeReminder() {
    final isPro = ref.read(proProvider).isPro;
    if (isPro) {
      return;
    }
    _reminderAt = ref.read(appDataProvider.notifier).defaultReminderFor(
          dueAt: _dueAt,
          dueHasTime: _dueHasTime,
        );
  }

  Future<void> _save() async {
    final groups = ref.read(groupsProvider);
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a group first.')),
      );
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title first.')),
      );
      return;
    }

    setState(() => _saving = true);
    final isPro = ref.read(proProvider).isPro;
    final reminder = isPro
        ? _reminderAt
        : ref.read(appDataProvider.notifier).defaultReminderFor(
              dueAt: _dueAt,
              dueHasTime: _dueHasTime,
            );
    final recurrence = isPro ? _recurrence : const Recurrence();
    final saved = widget.task.copyWith(
      groupId: _groupId,
      title: title,
      notes: _notesController.text.trim(),
      dueAt: _dueAt,
      dueHasTime: _dueHasTime,
      reminderAt: reminder,
      recurrence: recurrence,
      clearDueAt: _dueAt == null,
      clearReminderAt: reminder == null,
    );

    final result = await ref.read(appDataProvider.notifier).upsertTask(
          saved,
          isNew: widget.isNew,
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result == SaveTaskResult.blockedByTaskLimit) {
      await showPaywall(context);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(appDataProvider.notifier).deleteTask(widget.task.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
