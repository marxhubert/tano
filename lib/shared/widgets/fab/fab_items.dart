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
    required this.label,
    this.onTap,
    this.isActive = false,
    this.color,
    this.size,
  });

  final IconData icon;

  /// Accessibility label (also the tooltip) of the icon-only action.
  final String label;

  final VoidCallback? onTap;
  final bool isActive;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    // The open action keeps a plain white glyph: the darker menu surface
    // behind it already signals the active state.
    final Color base = color ?? Colors.white;
    // When disabled, every action borrows the neutral dimmed colour: a red
    // "delete" at 35% would be invisible on the teal FAB.
    final Color iconColor =
        onTap == null ? Colors.white.withValues(alpha: 0.35) : base;
    // The bar splits into equal, gapless full-height zones: each action fills
    // its own zone.
    final Widget button = IconButton(
      icon: Icon(icon, color: iconColor, size: size),
      tooltip: label,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
      ),
    );
    if (!isActive) return button;
    // The open action's zone flows into the menu through concave fillets at the
    // top, then tapers inwards towards a rounded bottom.
    return CustomPaint(
      painter: _ActiveZonePainter(color: _fabMenuSurface(context)),
      child: button,
    );
  }
}

/// Paints the open action's zone. Its top flares past the zone into the menu
/// (concave fillets that overlap the neighbouring zones), the sides taper
/// slightly inwards, and the bottom is rounded.
class _ActiveZonePainter extends CustomPainter {
  const _ActiveZonePainter({required this.color});

  final Color color;

  static const double _spill = 12.0;
  static const double _drop = 12.0;
  static const double _radius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    if (w <= 0 || h <= 0) return;

    final double radius = _radius
        .clamp(0.0, w / 2)
        .clamp(0.0, h / 2)
        .toDouble();
    final double drop = _drop.clamp(0.0, h - radius).toDouble();

    final Path path = Path()
      ..moveTo(-_spill, 0)

      // Top-left: opening outwards.
      ..quadraticBezierTo(0, 0, 0, drop)
      ..lineTo(0, h - radius)

      // Bottom-left: rounded corner.
      ..arcToPoint(
        Offset(radius, h),
        radius: Radius.circular(radius),
        clockwise: false,
      )

      // Bottom edge.
      ..lineTo(w - radius, h)

      // Bottom-right: rounded corner.
      ..arcToPoint(
        Offset(w, h - radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )

      ..lineTo(w, drop)

      // Top-right: opening outwards.
      ..quadraticBezierTo(w, 0, w + _spill, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _ActiveZonePainter oldDelegate) =>
      oldDelegate.color != color;
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

