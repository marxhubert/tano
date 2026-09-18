import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

// ---------------------------------------------------------------------------
// Title line
// ---------------------------------------------------------------------------

/// Size of a page / section title.
const double sectionTitleSize = 24.0;

/// Size of the small metadata printed at the right of a title line.
const double titleMetadataSize = 13.0;

/// The big title style (page title, group header).
TextStyle sectionTitleStyle(BuildContext context, {Color? color}) => TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: sectionTitleSize,
      letterSpacing: -0.41,
      color: color ?? primaryTextColor(context),
    );

/// Muted style shared by every title-line metadata (counts, selection).
TextStyle titleMetadataStyle(BuildContext context) => TextStyle(
      color: mutedTextColor(context),
      fontWeight: FontWeight.w400,
      fontSize: titleMetadataSize,
    );

/// One title line: the title on the left and a small metadata on the right,
/// both baseline-aligned. Being the only title-line brick, every screen drives
/// its own horizontal [padding] from it so the titles line up with the content.
class SectionTitleLine extends StatelessWidget {
  const SectionTitleLine({
    super.key,
    this.title,
    this.titleWidget,
    this.metadata,
    this.metadataWidget,
    this.padding = EdgeInsets.zero,
    this.titleStyle,
  });

  /// Plain title text, used when [titleWidget] is null.
  final String? title;

  /// Custom title widget (e.g. the editor's editable title field).
  final Widget? titleWidget;

  /// Small right-aligned metadata (count, selection message, ...).
  final String? metadata;

  /// Tappable metadata (a "Clear" action, ...). Wins over [metadata].
  final Widget? metadataWidget;

  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child:
                    titleWidget ??
                    Text(
                      title ?? '',
                      style: titleStyle ?? sectionTitleStyle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
              if (metadataWidget != null)
                Padding(
                  padding: const EdgeInsets.only(left: appPaddingMedium),
                  child: metadataWidget,
                )
              else if (metadata != null)
                Padding(
                  padding: const EdgeInsets.only(left: appPaddingMedium),
                  child: ConstrainedBox(
                    // The metadata only takes what it needs, up to 60% of the
                    // line: the title keeps the rest.
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.6,
                    ),
                    child: Text(
                      metadata!,
                      style: titleMetadataStyle(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metadata line
// ---------------------------------------------------------------------------

/// Size of a metadata-line glyph.
const double metadataIconSize = 12.0;

/// Muted style shared by every metadata-line value (date, counts, ...).
TextStyle metadataLineStyle(BuildContext context) => TextStyle(
      color: mutedTextColor(context),
      fontSize: TanoText.tiny,
    );

/// A bare glyph of the metadata line (lock, bookmark, ...).
Widget metadataGlyph(
  BuildContext context,
  IconData icon, {
  Color? color,
  double? fill,
}) => Icon(
  icon,
  size: metadataIconSize,
  color: color ?? mutedTextColor(context),
  fill: fill,
);

/// A glyph followed by its value ("x3").
Widget metadataItem(
  BuildContext context,
  IconData icon,
  String label, {
  Color? iconColor,
  double? fill,
}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: metadataIconSize,
          color: iconColor ?? mutedTextColor(context),
          fill: fill,
        ),
        Text(label, style: metadataLineStyle(context)),
      ],
    );

/// The line under a page title: a leading widget (date, count, ...) on the left
/// and small entries (flags, counters) on the right. One brick for the folder
/// page and the note editor, driven by its [padding].
class MetadataLine extends StatelessWidget {
  const MetadataLine({
    super.key,
    this.leading,
    this.trailing = const <Widget>[],
    this.padding = EdgeInsets.zero,
  });

  final Widget? leading;
  final List<Widget> trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(child: leading ?? const SizedBox.shrink()),
          for (final Widget item in trailing) ...<Widget>[
            const SizedBox(width: appPaddingTight),
            item,
          ],
        ],
      ),
    );
  }
}
