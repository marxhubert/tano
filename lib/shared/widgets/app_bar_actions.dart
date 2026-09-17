import 'package:flutter/material.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Size shared by the app-bar text actions: the reduced title and "Cancel".
const double appBarTextSize = 17.0;

/// The app-bar "Cancel" text button: the single reference for every screen
/// (same size, colour, padding and position).
class CancelButton extends StatelessWidget {
  const CancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: appPaddingMedium),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          AppText.tr('cancel'),
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: appBarTextSize,
            color: tanoBlue,
          ),
        ),
      ),
    );
  }
}

/// The "TanoNote" app-bar title: "Tano" bold, "Note" light.
class TanoAppBarTitle extends StatelessWidget {
  const TanoAppBarTitle({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolved = color ?? primaryTextColor(context);
    return RichText(
      text: TextSpan(
        text: AppConfig.appName,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: resolved,
          fontSize: appBarTextSize,
          letterSpacing: -0.41,
        ),
        children: <TextSpan>[
          TextSpan(
            text: AppConfig.appNameSuffix,
            style: TextStyle(
              fontWeight: FontWeight.w300,
              color: resolved,
              fontSize: appBarTextSize,
              letterSpacing: -0.41,
            ),
          ),
        ],
      ),
    );
  }
}
