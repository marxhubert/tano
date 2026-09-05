import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Shows an adaptive confirmation dialog (Material on Android, Cupertino on iOS).
Future<bool?> getConfirmation({
  required BuildContext context,
  required String actionTitle,
  required String action,
}) async {
  final ThemeData theme = Theme.of(context);
  final bool isSave = action.toLowerCase() == AppText.tr('save').toLowerCase();
  final bool isDestructive =
      action.toLowerCase() == AppText.tr('delete').toLowerCase() ||
          actionTitle.toLowerCase().contains('reset');

  if (theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS) {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(actionTitle),
        content: Text(AppText.tr('confirm_question')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDestructiveAction: isSave, // Match Material logic
            child: Text(isSave ? AppText.tr('quit') : AppText.tr('cancel')),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDefaultAction: true,
            isDestructiveAction: isDestructive,
            child: Text(action),
          ),
        ],
      ),
    );
  }

  // Fallback to Material AlertDialog (good for Android and tests)
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(actionTitle),
      content: Text(AppText.tr('confirm_question')),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            (isSave ? AppText.tr('quit') : AppText.tr('cancel')).toUpperCase(),
            style: TextStyle(color: isSave ? Colors.red : Colors.blue),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            action.toUpperCase(),
            style: TextStyle(color: isSave ? Colors.blue : Colors.red),
          ),
        ),
      ],
    ),
  );
}
