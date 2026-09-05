import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(title: AppText.tr('menu_theme')),
            SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemePreview(
                        title: AppText.tr('theme_light'),
                        isDark: false,
                        isSelected: !isAutomatic && currentMode == ThemeMode.light,
                        onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                      ),
                      _ThemePreview(
                        title: AppText.tr('theme_dark'),
                        isDark: true,
                        isSelected: !isAutomatic && currentMode == ThemeMode.dark,
                        onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
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
    final Color screenBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    final List<Color> mockColors = isDark
        ? [
            const Color(0xFF004D40),
            const Color(0xFF827717),
            const Color(0xFFBF360C),
            const Color(0xFF4A148C),
            const Color(0xFF880E4F),
            const Color(0xFF01579B),
            const Color(0xFF3E2723),
            const Color(0xFF1B5E20),
            const Color(0xFFAD1457),
          ]
        : [
            const Color(0xFFE0F2F1),
            const Color(0xFFFFF9C4),
            const Color(0xFFFFE0B2),
            const Color(0xFFF3E5F5),
            const Color(0xFFFFEBEE),
            const Color(0xFFE1F5FE),
            const Color(0xFFF5F5DC),
            const Color(0xFFF1F8E9),
            const Color(0xFFFCE4EC),
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
              borderRadius: BorderRadius.circular(isSelected ? 13.0 : 12.0),
              border: Border.all(
                color: isSelected ? tanoAmber : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: tanoTeal,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(11.0)),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 16,
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
                    padding: isSelected ? const EdgeInsets.all(3.0) : const EdgeInsets.all(4.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: mockColors.map((color) => _MockNoteCard(color: color)).toList(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(color: tanoTeal, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.0,
              color: primaryTextColor(context),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            isSelected ? Icons.check_circle : Icons.panorama_fish_eye,
            color: isSelected ? tanoAmber : Colors.grey.withValues(alpha: 0.5),
            size: 16,
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
