import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The kind of entity a card shows. Not used by the layout itself; it lets
/// callers and tests tell cards apart, and hosts future type-specific tweaks.
enum EntityKind { note, folder }

/// The only three card heights allowed by the design, shared by notes and
/// folders:
/// - [compact]: list row without a cover (80)
/// - [normal]: list row with a cover (92)
/// - [square]: grid tile (128), subtly taller than wide rather than a square
enum EntityCardHeight {
  compact(80.0),
  normal(92.0),
  square(128.0);

  const EntityCardHeight(this.value);

  final double value;
}

typedef EntityCardBodyBuilder = Widget Function(
  BuildContext context,
  Color textColor,
  bool hasCover,
);

/// The single card container (note, folder, later task/project).
///
/// Flat by design (no shadow), with a border that is dark in the light theme
/// and light in the dark theme. Locked cards get a discreet dashed outline
/// inset by [contentInset], the same margin used by the content and the
/// markers. The body comes from [builder].
class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.kind,
    required this.category,
    required this.builder,
    this.title = '',
    this.subtitle,
    this.subtitleIcon,
    this.coverImage,
    this.isImportant = false,
    this.isLocked = false,
    this.isListLayout = false,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.isSelectable = true,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
  });

  /// Margin between the card edge and the content, the markers and the locked
  /// dashes. One single value, so every card lines up.
  static const double contentInset = 6.0;

  /// Card radius.
  static const double outerRadius = appBorderRadius;

  /// Radius of anything inset by [contentInset]: outer - margin.
  static const double innerRadius = outerRadius - contentInset;

  /// Folder watermark glyph size: 24 (its native size) x 3. It is pushed past
  /// the bottom-right edges, so most of the glyph stays inside the card.
  static const double folderWatermarkSize = 72.0;

  final EntityKind kind;
  final String category;
  final EntityCardBodyBuilder builder;

  /// Title and secondary line used by the shared locked template. The optional
  /// [subtitleIcon] keeps a metadata glyph (e.g. the folder note count) on the
  /// locked card, exactly as the unlocked body shows it.
  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;

  final String? coverImage;
  final bool isImportant;
  final bool isLocked;
  final bool isListLayout;
  final bool isSelected;
  final bool isInSelectionMode;

  /// When false the selection circle is hidden (e.g. a locked folder).
  final bool isSelectable;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = themeCategory(
      category,
      true,
      brightness: Theme.of(context).brightness,
    );
    final Color textColor = getTextColor(bgColor);
    final Color borderColor = cardBorderColor(isDark);
    final bool showCover = coverImage != null && !isLocked;

    final Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double coverHeight =
              showCover && !isListLayout ? constraints.maxHeight / 2 : 0.0;
          final double coverWidth =
              showCover && isListLayout ? constraints.maxWidth / 3 : 0.0;
          return Stack(
            children: <Widget>[
              if (showCover)
                Positioned(
                  top: 0.0,
                  left: 0.0,
                  right: isListLayout ? null : 0.0,
                  bottom: isListLayout ? 0.0 : null,
                  width: isListLayout ? coverWidth : null,
                  height: isListLayout ? null : coverHeight,
                  // Hairline under the cover, like the cover rules of the managed
                  // cover; drawn on top of the image.
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cardBorderColor(isDark),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CoverImage(name: coverImage!),
                  ),
                ),
              // Folder watermark: the glyph bleeds off the bottom-right corner,
              // pushed 24px past both edges.
              if (kind == EntityKind.folder)
                Positioned(
                  right: -2.0,
                  bottom: -20.0,
                  width: folderWatermarkSize,
                  height: folderWatermarkSize,
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey<String>('entity-card-watermark'),
                      // A bookmarked folder turns its watermark amber.
                      painter: _FolderWatermarkPainter(
                        color: isImportant
                            ? tanoAmber.withValues(alpha: 0.45)
                            : textColor.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
              if (isLocked)
                ..._lockedOverlay(bgColor, textColor, isDark)
              else if (isListLayout)
                InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: EdgeInsets.only(left: coverWidth),
                    child: builder(context, textColor, showCover),
                  ),
                )
              else
                Positioned.fill(
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: EdgeInsets.only(top: coverHeight),
                      child: builder(context, textColor, showCover),
                    ),
                  ),
                ),
              if (isInSelectionMode)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: onSelectionToggle,
                    child: Container(
                      color: isSelected ? Colors.black38 : Colors.black12,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _selectionIcon(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              // The border is painted last, above the cover and the content, so
              // neither can hide it (which used to truncate the rounded corners
              // of a covered card). It is thicker in the dark theme, where a
              // hairline reads too faintly.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerRadius),
                      border: Border.all(
                        color: borderColor,
                        width: isDark ? 1.0 : 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    // A list card is one of two fixed heights; a grid card fills its cell.
    // Cards share the FAB's tap group: tapping one to open the entity must not
    // fold an open FAB while the page navigates away.
    return TapRegion(
      groupId: fabTapGroup,
      child: isListLayout
          ? SizedBox(
              height: (showCover
                      ? EntityCardHeight.normal
                      : EntityCardHeight.compact)
                  .value,
              child: card,
            )
          : card,
    );
  }

  List<Widget> _lockedOverlay(Color bgColor, Color textColor, bool isDark) {
    final Color dotColor = isDark
        ? Colors.white.withValues(alpha: 0.34)
        : Colors.black.withValues(alpha: 0.28);
    return <Widget>[
      Positioned.fill(
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            // A locked folder keeps its watermark visible through the overlay;
            // the card itself already paints [bgColor].
            color: kind == EntityKind.folder ? Colors.transparent : bgColor,
            // Grid keeps contentInset x2 on every side; the locked list gets
            // wider left/right gutters.
            padding: isListLayout
                ? const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: contentInset * 2.0,
                  )
                : const EdgeInsets.all(contentInset * 2.0),
            child: _lockedTemplate(textColor),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.all(contentInset),
            child: CustomPaint(
              key: const ValueKey<String>('entity-card-outline'),
              // Inner radius: the outline is inset by contentInset.
              painter: _DottedBorderPainter(
                color: dotColor,
                radius: innerRadius,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// Locked template, identical for every entity kind.
  Widget _lockedTemplate(Color textColor) {
    final Widget lock = Icon(
      // Material Symbols, so the weight axis is adjustable.
      Symbols.lock,
      size: 24.0,
      weight: 200,
      color: textColor.withValues(alpha: 0.6),
    );
    final String shownTitle = title.isEmpty ? AppText.tr('no_title') : title;
    final TextStyle titleStyle = TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final Color metaColor = textColor.withValues(alpha: 0.6);
    final Widget? meta = subtitle == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (subtitleIcon != null)
                Icon(subtitleIcon, size: 11.0, color: metaColor),
              Flexible(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.0, color: metaColor),
                ),
              ),
            ],
          );
    if (isListLayout) {
      return Center(
        child: Row(
          children: <Widget>[
            lock,
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    shownTitle,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  if (meta != null) ...<Widget>[
                    const SizedBox(height: 2.0),
                    meta,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          lock,
          const SizedBox(height: 6.0),
          Text(
            shownTitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
          if (meta != null) ...<Widget>[
            const SizedBox(height: 2.0),
            meta,
          ],
        ],
      ),
    );
  }

  Widget _selectionIcon(bool isDark) {
    if (!isSelectable) return const SizedBox.shrink();
    final Color color = isDark ? TanoStates.action.dark : tanoTeal;
    if (!isSelected) {
      return Icon(Icons.panorama_fish_eye, size: 24.0, color: color);
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const SizedBox(
          width: 18.0,
          height: 18.0,
          child: CircleAvatar(backgroundColor: Colors.white, radius: 100.0),
        ),
        Icon(Icons.check_circle, size: 24.0, color: color),
      ],
    );
  }
}

/// Draws a dotted rounded outline, used by locked cards.
class _DottedBorderPainter extends CustomPainter {
  const _DottedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  /// Distance between two dots and dot radius. Both stay small and constant, so
  /// the outline reads the same on the sides and around the corners.
  static const double _spacing = 5.0;
  static const double _dotRadius = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = math.min(radius, math.min(w, h) / 2);
    if (w <= 0 || h <= 0 || r <= 0) return;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)),
      );
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dots are spread evenly over the whole outline, corners included, so the
    // rhythm never widens where the border curves.
    for (final ui.PathMetric metric in path.computeMetrics()) {
      final double total = metric.length;
      if (total <= 0.0) continue;
      final int count = math.max(1, (total / _spacing).round());
      final double step = total / count;
      for (int i = 0; i < count; i++) {
        final ui.Tangent? tangent = metric.getTangentForOffset(i * step);
        if (tangent == null) continue;
        canvas.drawCircle(tangent.position, _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Stroke-only folder glyph used as the folder card watermark.
///
/// It is the outline "folder open" pictogram: the native artwork is a 24x24
/// viewBox stroked at 1.0, so the painter scales it to whatever box it is
/// given.
class _FolderWatermarkPainter extends CustomPainter {
  const _FolderWatermarkPainter({required this.color});

  final Color color;

  /// Native stroke width, in the 24x24 artwork space.
  static const double _nativeStroke = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double scale = size.width / 24.0;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _nativeStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);
    final Path path = Path()
      // Open flap.
      ..moveTo(2.25, 12.75)
      ..lineTo(2.25, 12.0)
      ..arcToPoint(
        const Offset(4.5, 9.75),
        radius: const Radius.circular(2.25),
      )
      ..lineTo(19.5, 9.75)
      ..arcToPoint(
        const Offset(21.75, 12.0),
        radius: const Radius.circular(2.25),
      )
      ..lineTo(21.75, 12.75)
      // Folder body.
      ..moveTo(13.06, 6.31)
      ..lineTo(10.94, 4.19)
      ..arcToPoint(
        const Offset(9.879, 3.75),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..lineTo(4.5, 3.75)
      ..arcToPoint(
        const Offset(2.25, 6.0),
        radius: const Radius.circular(2.25),
        clockwise: false,
      )
      ..lineTo(2.25, 18.0)
      ..arcToPoint(
        const Offset(4.5, 20.25),
        radius: const Radius.circular(2.25),
        clockwise: false,
      )
      ..lineTo(19.5, 20.25)
      ..arcToPoint(
        const Offset(21.75, 18.0),
        radius: const Radius.circular(2.25),
        clockwise: false,
      )
      ..lineTo(21.75, 9.0)
      ..arcToPoint(
        const Offset(19.5, 6.75),
        radius: const Radius.circular(2.25),
        clockwise: false,
      )
      ..lineTo(14.121, 6.75)
      ..arcToPoint(
        const Offset(13.061, 6.31),
        radius: const Radius.circular(1.5),
      )
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FolderWatermarkPainter old) =>
      old.color != color;
}
