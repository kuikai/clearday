import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_skin.dart';

/// Selectable cards for the appearance skins.
class SkinPicker extends StatelessWidget {
  const SkinPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.skins,
  });

  final AppSkin selected;
  final ValueChanged<AppSkin> onSelected;
  final List<AppSkin>? skins;

  @override
  Widget build(BuildContext context) {
    final choices = skins ?? AppSkin.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        final skin = choices[index];
        return _SkinCard(
          skin: skin,
          selected: skin == selected,
          onTap: () => onSelected(skin),
        );
      },
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _SkinColors.of(skin, theme.brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: _decoration(theme, colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _SkinPreview(colors: colors, selected: selected),
              ),
              Expanded(
                flex: 4,
                child: _SkinCaption(skin: skin, colors: colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(ThemeData theme, _SkinColors colors) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: selected
            ? colors.primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        width: selected ? 2.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: selected ? 0.14 : 0.06),
          blurRadius: selected ? 14 : 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({required this.colors, required this.selected});

  final _SkinColors colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ColourSample(colors: colors),
          if (selected)
            Positioned(
              right: 8,
              top: 8,
              child: _SelectedMark(color: colors.primary),
            ),
        ],
      ),
    );
  }
}

class _ColourSample extends StatelessWidget {
  const _ColourSample({required this.colors});

  final _SkinColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.background,
            Color.lerp(colors.background, colors.primary, 0.18)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(left: 12, top: 12, child: _SampleChip(colors: colors)),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              'Today',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.colors});

  final _SkinColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Aa',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle_rounded, color: color, size: 22),
    );
  }
}

class _SkinCaption extends StatelessWidget {
  const _SkinCaption({required this.skin, required this.colors});

  final AppSkin skin;
  final _SkinColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Swatch(color: colors.primary),
              const SizedBox(width: 6),
              _Swatch(color: colors.accent),
              const SizedBox(width: 6),
              _Swatch(color: colors.background),
            ],
          ),
          const Spacer(),
          Text(
            skin.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            skin.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.58),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
    );
  }
}

class _SkinColors {
  const _SkinColors({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.onSurface,
  });

  factory _SkinColors.of(AppSkin skin, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return _SkinColors(
      primary: skin.previewColor(brightness),
      onPrimary: skin.previewOnColor(brightness),
      background: dark ? skin.darkBackground : skin.lightBackground,
      surface: dark ? skin.darkSurface : AppColors.lightSurface,
      onSurface: dark ? skin.darkOnSurface : skin.lightOnSurface,
    );
  }

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color onSurface;

  Color get accent => Color.lerp(background, primary, 0.45)!;
}
