import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The illustrations are decorative: drawn this faint, they read as a
/// watermark behind the message rather than as an object of their own.
const double _emptyArtOpacity = 0.5;

/// The empty-state illustrations.
///
/// Drawn by Ghozi Muhtarom and published on Flaticon, which is why they are
/// credited in CREDITS.md, at the root of the repository. Do not remove the
/// credit without replacing the files.
class EmptyArt {
  static const String box = 'assets/icons/Ghozi_Muhtarom/empty-box.png';
  static const String folder = 'assets/icons/Ghozi_Muhtarom/empty-folder.png';
  static const String bin = 'assets/icons/Ghozi_Muhtarom/recycle-bin.png';
  static const String search = 'assets/icons/Ghozi_Muhtarom/empty.png';
}

/// The one way to say "there is nothing here".
///
/// Centred, muted, at the label size, so every empty screen of the app reads
/// the same. [image] is one of [EmptyArt].
Widget emptyState(BuildContext context, String message, {String? image}) {
  return Center(
    child: Padding(
      // Optical centring: half of this padding falls under the middle of the
      // screen, so the block sits a little above the exact centre.
      padding: const EdgeInsets.only(bottom: 6 * sectionGap),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (image != null) ...<Widget>[
            Opacity(
              opacity: _emptyArtOpacity,
              child: Image.asset(
                image,
                width: 96.0,
                height: 96.0,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: appPaddingMedium),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TanoText.label,
              color: mutedTextColor(context),
            ),
          ),
        ],
      ),
    ),
  );
}
