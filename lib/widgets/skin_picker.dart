import 'package:flutter/material.dart';

import '../core/theme/app_skin.dart';

/// Color swatches for the basic appearance skins.
class SkinPicker extends StatelessWidget {
  const SkinPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSkin selected;
  final ValueChanged<AppSkin> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final skin in AppSkin.values)
          _SkinOption(
            skin: skin,
            selected: skin == selected,
            onSelected: () => onSelected(skin),
          ),
      ],
    );
  }
}

class _SkinOption extends StatelessWidget {
  const _SkinOption({
    required this.skin,
    required this.selected,
    required this.onSelected,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Semantics(
      button: true,
      selected: selected,
      label: skin.label,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: onSelected,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SkinSwatch(
                  color: skin.previewColor(brightness),
                  checkColor: skin.previewOnColor(brightness),
                  selected: selected,
                  borderColor: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  skin.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: selected ? 1 : 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinSwatch extends StatelessWidget {
  const _SkinSwatch({
    required this.color,
    required this.checkColor,
    required this.selected,
    required this.borderColor,
  });

  final Color color;
  final Color checkColor;
  final bool selected;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: checkColor, size: 22)
          : null,
    );
  }
}
