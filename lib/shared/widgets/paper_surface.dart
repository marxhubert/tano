import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The site's ruled hero paper, painted once behind each route. Decorative
/// layers never participate in pointer handling or accessibility semantics.
class PaperSurface extends StatelessWidget {
  const PaperSurface({super.key, required this.child, this.notebook = false});
  final Widget child;
  final bool notebook;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PaperPainter(
                paper: barColor(context),
                rule: paperRuleColor(context),
                grain: primaryTextColor(context).withValues(alpha: .025),
                margin: amberColor(context).withValues(alpha: .22),
                notebook: notebook,
                spacing: 34 * MediaQuery.textScalerOf(context).scale(1),
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({
    required this.paper,
    required this.rule,
    required this.grain,
    required this.margin,
    required this.notebook,
    required this.spacing,
  });
  final Color paper, rule, grain, margin;
  final bool notebook;
  final double spacing;

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
        const Offset(7, 0),
        Offset(7, size.height),
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
      spacing != old.spacing;
}
