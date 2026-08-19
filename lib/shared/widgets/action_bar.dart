import 'package:flutter/material.dart';

/// Compact icon button used in the bottom action bars.
///
/// Centralizes the shared styling (zero padding, no minimum constraints,
/// expanded flex) so the home and editor screens stay consistent.
class BottomActionButton extends StatelessWidget {
  const BottomActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24.0,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }
}
