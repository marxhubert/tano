import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';

Future<bool?> getConfirmation({
  required BuildContext context,
  required String actionTitle,
  required String action,
}) async {
  final bool isSave = action.toLowerCase() == AppText.tr('save').toLowerCase();
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        // Keeps the dialog usable on very short windows or at large text
        // scales: title and content scroll when space runs out.
        scrollable: true,
        title: Text(actionTitle),
        content: Text(AppText.tr('confirm_question')),
        actions: <Widget>[
          TextButton(
            child: Text(
              isSave ? AppText.tr('quit') : AppText.tr('cancel'),
              style: TextStyle(color: isSave ? Colors.red : Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(
              action.toUpperCase(),
              style: TextStyle(color: isSave ? Colors.blue : Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}
