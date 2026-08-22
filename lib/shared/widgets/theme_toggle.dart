import 'package:flutter/material.dart';
import 'package:tano/shared/config/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        
        return IconButton(
          icon: Icon(
            isDark ? Icons.sunny : Icons.dark_mode,
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
    );
  }
}
