import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The site's ruled hero paper, painted once behind each route. Decorative
/// layers never participate in pointer handling or accessibility semantics.
class PaperSurface extends StatelessWidget {
  const PaperSurface({
    super.key,
    required this.child,
    this.notebook = false,
    this.paper,
  });
  final Widget child;
  final bool notebook;

  /// The paper's own colour. Null keeps the default: a note or a folder passes
  /// its tone here, so the sheet itself takes the colour it stands for.
  final Color? paper;

  @override
  Widget build(BuildContext context) {
    // The notebook margin follows the content: on a landscape phone the island
    // pushes the writing in, and the margin line has to move with it.
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double sideInset = safe.left > safe.right ? safe.left : safe.right;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PaperPainter(
                  paper: paper ?? barColor(context),
                  rule: paperRuleColor(context),
                  // The site's own paper grain, at the strength its background
                  // shows. The dark page needs it to read as the same material.
                  grain: primaryTextColor(context).withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? .085
                        : .025,
                  ),
                  margin: amberColor(context).withValues(alpha: .22),
                  notebook: notebook,
                  spacing: 34 * MediaQuery.textScalerOf(context).scale(1),
                  marginX: 7.0 + sideInset,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({
    required this.paper,
    required this.rule,
    required this.grain,
    required this.margin,
    required this.notebook,
    required this.spacing,
    required this.marginX,
  });
  final Color paper, rule, grain, margin;
  final bool notebook;
  final double spacing;
  final double marginX;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final pen = Paint()
      ..color = rule
      ..strokeWidth = .7;
    for (double y = 22; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
    // A fixed seed keeps grain still during scrolling and theme transitions.
    final random = math.Random(42);
    final dots = List.generate(
      (size.width * size.height / 95).ceil(),
      (_) => Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ),
    );
    canvas.drawPoints(
      ui.PointMode.points,
      dots,
      Paint()
        ..color = grain
        ..strokeWidth = .8,
    );
    if (notebook) {
      canvas.drawLine(
        Offset(marginX, 0),
        Offset(marginX, size.height),
        Paint()
          ..color = margin
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      paper != old.paper ||
      rule != old.rule ||
      grain != old.grain ||
      margin != old.margin ||
      notebook != old.notebook ||
      spacing != old.spacing ||
      marginX != old.marginX;
}
