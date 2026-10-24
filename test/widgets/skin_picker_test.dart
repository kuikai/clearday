import 'package:clearday/core/theme/app_colors.dart';
import 'package:clearday/core/theme/app_skin.dart';
import 'package:clearday/core/theme/app_theme.dart';
import 'package:clearday/widgets/skin_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkinPicker shows every skin and reports a tap', (tester) async {
    AppSkin? chosen;
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkinPicker(
            selected: AppSkin.clear,
            onSelected: (skin) => chosen = skin,
          ),
        ),
      ),
    );

    for (final skin in AppSkin.values) {
      expect(find.text(skin.label), findsOneWidget);
      expect(find.text(skin.description), findsOneWidget);
    }

    await tester.tap(find.text('Ocean'));
    await tester.pump();

    expect(chosen, AppSkin.ocean);
  });

  testWidgets('themes use each skin palette', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final clearLight = AppTheme.light();
    final clearDark = AppTheme.dark();
    expect(clearLight.colorScheme.primary, AppColors.teal);
    expect(clearLight.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(clearDark.colorScheme.primary, AppColors.tealGlow);
    expect(clearDark.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(clearDark.colorScheme.onPrimary, const Color(0xFF06201C));

    for (final skin in AppSkin.values) {
      final light = AppTheme.light(skin: skin);
      final dark = AppTheme.dark(skin: skin);
      expect(light.colorScheme.primary, skin.lightPrimary);
      expect(light.scaffoldBackgroundColor, skin.lightBackground);
      expect(dark.colorScheme.primary, skin.darkPrimary);
      expect(dark.scaffoldBackgroundColor, skin.darkBackground);
    }
  });

  test('preview colors follow brightness', () {
    expect(
      AppSkin.ember.previewColor(Brightness.light),
      AppSkin.ember.lightPrimary,
    );
    expect(
      AppSkin.ember.previewColor(Brightness.dark),
      AppSkin.ember.darkPrimary,
    );
    expect(
      AppSkin.ember.previewOnColor(Brightness.dark),
      AppSkin.ember.darkOnPrimary,
    );
  });
}
