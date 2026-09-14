import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/theme.dart';

/// A cover image with the page-level affordances: an optional reserved height,
/// long-press to reveal a remove button, a confirmation before removal, a
/// "corrupted image" state, and top/bottom rules like the card border.
///
/// The drawing (image, placeholder, dim layer) comes from [CoverImage].
class ManageableCover extends StatefulWidget {
  const ManageableCover({
    super.key,
    required this.name,
    required this.onRemove,
    this.height,
    this.fit = BoxFit.cover,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0),
    this.lightDimAlpha = 0.12,
  });

  /// Stored cover name.
  final String name;

  /// Removes the cover. Runs only after the user confirms.
  final Future<void> Function() onRemove;

  /// Fixed height of the cover, cropped by [fit]. When null the image keeps
  /// its own aspect ratio at full width (the note editor) instead of being
  /// cropped.
  final double? height;

  /// How the image fills its box when [height] is set.
  final BoxFit fit;

  /// Outer padding; both covers are full width.
  final EdgeInsets padding;

  /// Dim applied in the light theme (the dark theme always dims at 0.3).
  final double lightDimAlpha;

  @override
  State<ManageableCover> createState() => _ManageableCoverState();
}

class _ManageableCoverState extends State<ManageableCover> {
  bool _showRemoveButton = false;
  bool _corrupted = false;

  Future<void> _confirmRemove() async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('delete_photo'),
      action: AppText.tr('delete'),
    );
    if (confirm != true || !mounted) return;
    await widget.onRemove();
    if (mounted) setState(() => _showRemoveButton = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Same border as the card: light 1.0 in dark, dark 0.5 in light.
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.16);
    final double borderWidth = isDark ? 1.0 : 0.5;

    final Widget image = CoverImage(
      name: widget.name,
      fit: widget.fit,
      expand: widget.height != null,
      lightDimAlpha: widget.lightDimAlpha,
      onError: () {
        if (mounted) setState(() => _corrupted = true);
      },
    );

    return Padding(
      padding: widget.padding,
      child: TapRegion(
        // Tapping elsewhere hides the remove button.
        onTapOutside: (_) {
          if (_showRemoveButton) {
            setState(() => _showRemoveButton = false);
          }
        },
        child: GestureDetector(
          // Long press reveals the remove button, like a note's cover.
          onLongPress: () =>
              setState(() => _showRemoveButton = !_showRemoveButton),
          child: Stack(
            children: <Widget>[
              if (widget.height == null)
                image
              else
                SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: image,
                ),
              // Top and bottom rules, like the card border.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: borderColor, width: borderWidth),
                        bottom:
                            BorderSide(color: borderColor, width: borderWidth),
                      ),
                    ),
                  ),
                ),
              ),
              if (_corrupted)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      AppText.tr('corrupted_image'),
                      style: TextStyle(
                        color: mutedTextColor(context),
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ),
              if (_corrupted || _showRemoveButton)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: GestureDetector(
                    onTap: _confirmRemove,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4.0,
                            offset: Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
