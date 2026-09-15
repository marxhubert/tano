part of 'app_fab.dart';

class _SubMenuLayout extends StatelessWidget {
  const _SubMenuLayout({
    required this.title,
    required this.onBack,
    required this.child,
    this.actions = const [],
    this.isMeasurement = false,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<Widget> actions;

  /// In the offstage measurement pass the body is laid out at its natural
  /// height (no scroll view), so the reported height matches the real menu.
  final bool isMeasurement;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed Header. The action buttons keep a 48px tap target, so their
        // glyph sits ~10px inside their box: the right padding is reduced to
        // line the last icon up with the back action on the left.
        Container(
          padding: const EdgeInsets.fromLTRB(20.0, 2.0, 10.0, 2.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(
                  Symbols.arrow_back_ios,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 17.0),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
        ),
        // Scrollable Body. The dark surface comes from the menu area itself.
        if (isMeasurement)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: child,
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: child,
            ),
          ),
      ],
    );
  }
}

/// One action of a horizontal FAB bar: icon only, one shared size, with an
/// optional accent colour and a disabled (dimmed) state.
class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.color,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? (isActive ? tanoAmber : Colors.white);
    // When disabled, every action borrows the neutral dimmed colour: a red
    // "delete" at 35% would be invisible on the teal FAB.
    final Color iconColor =
        onTap == null ? Colors.white.withValues(alpha: 0.35) : base;
    return IconButton(
      icon: Icon(icon, color: iconColor, size: size),
      onPressed: onTap,
    );
  }
}

class _VerticalMenuItem extends StatelessWidget {
  const _VerticalMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.iconSize = 20.0,
    this.fontSize = 17.0,
    this.maxLines,
    this.fill,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;
  final double fontSize;
  final int? maxLines;

  /// Material Symbols FILL axis: 0 = outlined, 1 = filled.
  final double? fill;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: maxLines != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: iconSize, fill: fill),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: fontSize,
                ),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

