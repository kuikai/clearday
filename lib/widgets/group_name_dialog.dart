import 'package:flutter/material.dart';

Future<String?> promptGroupName(
  BuildContext context, {
  required String title,
  String? initial,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          // Don't autofocus — on Samsung that immediately opens the keyboard
          // floating toolbar (mic / emoji bar) over the dialog.
          autofocus: false,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
          decoration: const InputDecoration(
            hintText: 'House Work, Workout, Work…',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

Future<bool> confirmDeleteGroup(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          '“$name” and everything inside it will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
