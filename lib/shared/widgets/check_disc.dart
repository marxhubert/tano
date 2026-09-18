import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The "this one is chosen" mark: a filled disc with the check cut into it.
///
/// The filled [Symbols.check_circle] glyph knocks its check out to whatever is
/// behind it: white on a light surface, but the surface itself on a dark one.
/// The white disc behind keeps the check white in both themes.
class CheckDisc extends StatelessWidget {
  const CheckDisc({super.key, this.size = 20.0, this.color});

  /// Height and width of the glyph.
  final double size;

  /// The disc's colour. Defaults to the app's primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: size * 0.75,
          height: size * 0.75,
          child: const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 100.0,
          ),
        ),
        Icon(
          Symbols.check_circle,
          fill: 1.0,
          size: size,
          color: color ?? tanoTeal,
        ),
      ],
    );
  }
}
