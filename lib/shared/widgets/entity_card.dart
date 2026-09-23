import 'package:tano/core/models/content_entity.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/card_typography.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/check_disc.dart';
import 'package:tano/shared/widgets/theme.dart';

export 'package:tano/core/models/content_entity.dart' show EntityKind;

/// The only three card heights allowed by the design, shared by notes and
/// folders:
/// - [compact]: list row without a cover (100)
/// - [normal]: list row with a cover (112)
/// - [square]: grid tile reference height (176), sized by the responsive view
enum EntityCardHeight {
  compact(100.0),
  normal(112.0),
  square(176.0);

  const EntityCardHeight(this.value);

  final double value;
}

typedef EntityCardBodyBuilder =
    Widget Function(BuildContext context, Color textColor, bool hasCover);

/// The single card container (note, folder, later task/project).
///
/// A warm paper surface with a fine rule and a quiet lifted shadow.
/// Locked cards get a discreet dashed outline
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
  static const double outerRadius = 8.0;

  /// Radius of anything inset by [contentInset]: outer - margin.
  static const double innerRadius = outerRadius - contentInset;

  /// A folder always carries a watermark, a grid cover earns one too, and a
  /// locked card keeps its own. The glyph is 24 (its native size) x 3 and
  /// bleeds past the right edge.
  static const double watermarkSize = 72.0;
  static const double _folderWatermarkRight = -16.0;

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
    final Color textColor = cardTextColor(context, category);
    final Color borderColor = cardBorderColor(isDark);
    final bool showCover = coverImage != null && !isLocked;
    // Keep dates and titles clear of the selection control. A grid cover
    // already provides an independent area for the control.
    final double selectionInset =
        isInSelectionMode && isSelectable && (isListLayout || !showCover)
        ? 24.0
        : 0.0;

    final Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(
              0xFF261A06,
            ).withValues(alpha: isDark ? 0.3 : 0.14),
            blurRadius: 12.0,
            spreadRadius: -6.0,
            offset: const Offset(0.0, 5.0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double coverHeight = showCover && !isListLayout
              ? constraints.maxHeight / 2
              : 0.0;
          final double coverWidth = showCover && isListLayout
              ? constraints.maxWidth / 3
              : 0.0;
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
                  // Thin rule between the cover and the content, in the card
                  // border colour; drawn on top of the image. It faces the
                  // content: bottom in the grid (cover on top), right in the
                  // list (cover on the left).
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: isListLayout
                          ? Border(
                              right: BorderSide(
                                color: cardBorderColor(isDark),
                                width: 1.0,
                              ),
                            )
                          : Border(
                              bottom: BorderSide(
                                color: cardBorderColor(isDark),
                                width: 1.0,
                              ),
                            ),
                    ),
                    child: CoverImage(name: coverImage!),
                  ),
                ),
              // Folder watermark: the glyph bleeds off the bottom-right corner,
              // pushed past both edges. A cover carries one too, but only in the
              // grid: a list's cover takes the left third and leaves no room.
              // The other kinds keep one while they are locked, the same way a
              // locked card is closed off.
              if (kind == EntityKind.folder ||
                  isLocked ||
                  (showCover && !isListLayout))
                Positioned(
                  right: _folderWatermarkRight,
                  bottom: -8.0,
                  width: watermarkSize,
                  height: watermarkSize,
                  child: IgnorePointer(
                    child: Icon(
                      // The kind's own mark: a folder, a note or a task.
                      switch (kind) {
                        EntityKind.task => Symbols.list_alt,
                        EntityKind.folder => Symbols.folder_open,
                        _ => Symbols.sticky_note_2,
                      },
                      key: const ValueKey<String>('entity-card-watermark'),
                      size: watermarkSize,
                      weight: 100.0,
                      color: textColor.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              if (isLocked)
                ..._lockedOverlay(textColor)
              else if (isListLayout)
                // Fill the whole card: a list card has a fixed height, and an
                // overlay (like the trash actions) must be positioned against
                // the card, not against the intrinsic content box.
                Positioned.fill(
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: coverWidth,
                        right: selectionInset,
                      ),
                      child: builder(context, textColor, showCover),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: coverHeight,
                        right: selectionInset,
                      ),
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
                          padding: const EdgeInsets.all(appPaddingTight),
                          child: _selectionIcon(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              // The border is painted last, above the cover and the content, so
              // neither can hide the rounded paper edge.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerRadius),
                      border: Border.all(color: borderColor, width: 1.0),
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
              height:
                  (showCover
                          ? EntityCardHeight.normal
                          : EntityCardHeight.compact)
                      .value,
              child: card,
            )
          : card,
    );
  }

  List<Widget> _lockedOverlay(Color textColor) {
    final Color dotColor = textColor.withValues(alpha: 0.3);
    return <Widget>[
      Positioned.fill(
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            // Transparent, so the lock overlay sits on the card's own colour:
            // the card itself already paints [bgColor].
            color: Colors.transparent,
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
      color: cardMutedColor(textColor),
    );
    final String shownTitle = title.isEmpty ? AppText.tr('no_title') : title;
    final TextStyle titleStyle = cardTitleStyle(textColor);
    final Color metaColor = cardMutedColor(textColor);
    final Widget? meta = subtitle == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (subtitleIcon != null)
                Icon(subtitleIcon, size: cardMetaIconSize, color: metaColor),
              Flexible(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cardMetaStyle(metaColor),
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
          if (meta != null) ...<Widget>[const SizedBox(height: 2.0), meta],
        ],
      ),
    );
  }

  Widget _selectionIcon(bool isDark) {
    if (!isSelectable) return const SizedBox.shrink();
    final Color color = isDark ? TanoStates.action.dark : tanoTeal;
    if (!isSelected) {
      return Icon(Symbols.circle, size: 24.0, color: color);
    }
    return CheckDisc(size: 24.0, color: color);
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
