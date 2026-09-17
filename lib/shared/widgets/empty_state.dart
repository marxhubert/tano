import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The empty-state illustrations.
///
/// Drawn by Ghozi Muhtarom and published on Flaticon, which is why they are
/// credited in the Licenses screen. Do not remove the credit without replacing
/// the files.
class EmptyArt {
  static const String box = 'assets/icons/Ghozi_Muhtarom/empty-box.png';
  static const String folder = 'assets/icons/Ghozi_Muhtarom/empty-folder.png';
  static const String bin = 'assets/icons/Ghozi_Muhtarom/recycle-bin.png';
  static const String search = 'assets/icons/Ghozi_Muhtarom/empty.png';
}

/// The one way to say "there is nothing here".
///
/// Centred, muted, at the label size, so every empty screen of the app reads
/// the same. [image] is one of [EmptyArt]; [actions] are laid out under the
/// message when the screen has something to offer (the bin proposes to go back
/// home, for instance).
Widget emptyState(
  BuildContext context,
  String message, {
  String? image,
  List<Widget> actions = const <Widget>[],
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (image != null) ...<Widget>[
          Image.asset(image, width: 96.0, height: 96.0, fit: BoxFit.contain),
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
        if (actions.isNotEmpty) ...<Widget>[
          const SizedBox(height: appPaddingWide),
          ...actions,
        ],
      ],
    ),
  );
}
