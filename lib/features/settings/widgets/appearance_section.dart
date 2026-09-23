import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/check_disc.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'settings_widgets.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final ThemeMode currentMode = ThemeController.instance.themeMode;
        final bool isAutomatic = currentMode == ThemeMode.system;

        return SettingsGroup(
          title: AppText.tr('menu_theme'),
          tiles: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: sectionGap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThemePreview(
                    title: AppText.tr('theme_light'),
                    isDark: false,
                    isSelected: !isAutomatic && currentMode == ThemeMode.light,
                    onTap: () =>
                        ThemeController.instance.setThemeMode(ThemeMode.light),
                  ),
                  _ThemePreview(
                    title: AppText.tr('theme_dark'),
                    isDark: true,
                    isSelected: !isAutomatic && currentMode == ThemeMode.dark,
                    onTap: () =>
                        ThemeController.instance.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            SettingsSwitchTile(
              title: AppText.tr('theme_automatic'),
              value: isAutomatic,
              onChanged: (val) {
                ThemeController.instance.setThemeMode(
                  val
                      ? ThemeMode.system
                      : (Theme.of(context).brightness == Brightness.dark
                            ? ThemeMode.dark
                            : ThemeMode.light),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.title,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color screenBg = isDark ? darkBackground : lightBackground;

    // Straight from the palette: a change there shows here, and the two can no
    // longer drift apart. "nuage" is left out, it is the surface colour.
    final List<Color> mockColors = <Color>[
      for (final ({Color light, Color dark, String name}) pastel
          in TanoPastels.all)
        if (pastel.name != 'nuage') (isDark ? pastel.dark : pastel.light),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              color: screenBg,
              // The frame never moves: selecting only changes colours, and the
              // chosen mock earns a halo drawn outside its box.
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                // The unselected outline uses the section border colour, so the
                // mock and the card around it share one rule.
                color: isSelected ? tanoAmber : cardBorderColor(isDark),
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: tanoAmber.withValues(alpha: 0.28),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 18,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: tanoTeal,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(11.0),
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: Theme.of(context).platform == TargetPlatform.android
                        ? 5
                        : 16,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 20,
                  child: Padding(
                    // Constant, unlike the selection: the little cards never
                    // slide when the choice changes.
                    padding: const EdgeInsets.all(4.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: mockColors
                          .map((color) => _MockNoteCard(color: color))
                          .toList(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: tanoTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.add,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            // Normal in both states: a bold label would widen the column and
            // nudge the whole row sideways.
            style: TextStyle(
              fontSize: TanoText.listTitle,
              color: primaryTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          if (isSelected)
            const CheckDisc(color: tanoAmber)
          else
            Icon(
              Symbols.circle,
              color: Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _MockNoteCard extends StatelessWidget {
  const _MockNoteCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
