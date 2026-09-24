import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The two actions a trashed or archived card carries, overlaid on its content:
/// restore (or unarchive) and delete. Identical in both places, so a change
/// reaches both.
class EntityCardActions extends StatelessWidget {
  const EntityCardActions({
    super.key,
    required this.isListLayout,
    required this.onRestore,
    required this.onDelete,
    required this.textColor,
    this.restoreIcon = Symbols.undo,
  });

  /// The card's layout, so the actions sit where the trash puts them.
  final bool isListLayout;

  final VoidCallback onRestore;

  /// Deletion asks for a confirmation, so it is asynchronous.
  final Future<void> Function() onDelete;

  /// The card's own ink, for the restore action.
  final Color textColor;

  final IconData restoreIcon;

  @override
  Widget build(BuildContext context) {
    final Widget restore = _EntityAction(
      icon: restoreIcon,
      onTap: onRestore,
      color: textColor.withValues(alpha: 0.9),
    );
    final Widget delete = _EntityAction(
      icon: Symbols.delete_forever,
      onTap: onDelete,
      color: TanoStates.error.dark,
    );
    if (isListLayout) {
      // In a list the two sit centred, 8 px above the bottom edge.
      return Positioned(
        bottom: 8.0,
        left: 0.0,
        right: 0.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12.0,
          children: <Widget>[restore, delete],
        ),
      );
    }
    return Positioned(
      bottom: 6.0,
      left: 0.0,
      right: 0.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[restore, delete],
      ),
    );
  }
}

class _EntityAction extends StatelessWidget {
  const _EntityAction({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(appPaddingSmall),
        decoration: BoxDecoration(
          color: barColor(context),
          shape: BoxShape.circle,
          // A hairline keeps the glyph readable on pale cards.
          border: Border.all(
            color: primaryTextColor(context).withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
