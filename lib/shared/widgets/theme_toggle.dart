import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Sharing the FAB's tap group keeps an open FAB menu open when the theme
    // is toggled from the app bar.
    return TapRegion(
      groupId: fabTapGroup,
      child: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          return IconButton(
            visualDensity: VisualDensity.compact,
            // Light mode shows the moon, dark mode the sun: switching is
            // explicit about what comes next.
            icon: Icon(
              isDark ? Symbols.light_mode : Symbols.dark_mode,
              color: color,
              size: 22.0,
            ),
            onPressed: () {
              ThemeController.instance.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          );
        },
      ),
    );
  }
}
