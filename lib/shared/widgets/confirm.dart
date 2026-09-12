import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';


/// One option of [showAdaptiveChoice].
class AdaptiveChoice<T> {
  const AdaptiveChoice({required this.label, required this.value});

  final String label;
  final T value;
}

/// Shows a list of choices: an iOS action sheet on iOS/macOS and a Material
/// dialog elsewhere. Returns the chosen value, or null when dismissed.
Future<T?> showAdaptiveChoice<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveChoice<T>> choices,
}) async {
  final ThemeData theme = Theme.of(context);
  final bool isApple =
      theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS;

  if (isApple) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        title: Text(title),
        actions: <Widget>[
          for (final AdaptiveChoice<T> choice in choices)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(popupContext, choice.value),
              child: Text(choice.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(popupContext),
          child: Text(AppText.tr('cancel')),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (BuildContext dialogContext) => SimpleDialog(
      title: Text(title),
      children: <Widget>[
        for (final AdaptiveChoice<T> choice in choices)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, choice.value),
            child: Text(choice.label),
          ),
      ],
    ),
  );
}

/// Shows an adaptive confirmation dialog (Material on Android, Cupertino on iOS).
Future<bool?> getConfirmation({
  required BuildContext context,
  required String actionTitle,
  required String action,
  String? message,
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
        content: Text(message ?? AppText.tr('confirm_question')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDestructiveAction: isSave,
            child: Text(
              isSave ? AppText.tr('quit') : AppText.tr('cancel'),
              style: TextStyle(
                color: isSave ? Colors.red : primaryTextColor(context),
                fontSize: 17.0,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDefaultAction: true,
            isDestructiveAction: isDestructive,
            child: Text(
              action,
              style: TextStyle(
                color: isDestructive ? Colors.red : tanoTeal,
                fontSize: 17.0,
                fontWeight: isDestructive ? FontWeight.normal : FontWeight.bold,
              ),
            ),
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
      content: Text(message ?? AppText.tr('confirm_question')),
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

/// Shows an adaptive informational alert (Material on Android, Cupertino on
/// iOS) with a single dismiss button.
Future<void> showAdaptiveAlert({
  required BuildContext context,
  required String title,
  String? message,
}) async {
  final ThemeData theme = Theme.of(context);
  final bool isApple =
      theme.platform == TargetPlatform.iOS ||
          theme.platform == TargetPlatform.macOS;

  if (isApple) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.tr('ok')),
          ),
        ],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppText.tr('ok').toUpperCase()),
        ),
      ],
    ),
  );
}

/// Shows a short message. Android gets an idiomatic [SnackBar]; iOS has no
/// native transient banner, so it falls back to the adaptive alert.
Future<void> showAdaptiveNotice(BuildContext context, String message) async {
  final ThemeData theme = Theme.of(context);
  if (theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS) {
    await showAdaptiveAlert(context: context, title: message);
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

/// Shows a short message with a single action (e.g. "Undo"). Android gets a
/// [SnackBar]; iOS gets an adaptive alert, since it has no native transient
/// banner.
Future<void> showAdaptiveNoticeWithAction({
  required BuildContext context,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  Duration duration = const Duration(seconds: 3),
}) async {
  final ThemeData theme = Theme.of(context);
  if (theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.tr('ok')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      // A SnackBar with an action defaults to persist: true, which makes the
      // timeout a no-op. Opt back into the timed auto-dismiss.
      persist: false,
      action: SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}
