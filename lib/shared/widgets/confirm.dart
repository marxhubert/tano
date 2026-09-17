import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Shows an adaptive confirmation dialog (Material on Android, Cupertino on iOS).
Future<bool?> getConfirmation({
  required BuildContext context,
  required String actionTitle,
  required String action,
  String? message,
}) async {
  final ThemeData theme = Theme.of(context);
  final bool isSave = action.toLowerCase() == AppText.tr('save').toLowerCase();
  // Compared against the translated words: a dialog must never change colour
  // with the language. This used to test actionTitle.contains('reset'), and
  // the French word does not contain it: the reset action came out blue in
  // French and in Malagasy.
  final String lowered = action.toLowerCase();
  final bool isDestructive =
      lowered == AppText.tr('delete').toLowerCase() ||
      lowered == AppText.tr('reset').toLowerCase();

  if (theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS) {
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
                fontSize: TanoText.listTitle,
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
                color: isDestructive ? Colors.red : tanoBlue,
                fontSize: TanoText.listTitle,
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
            style: TextStyle(color: isSave ? Colors.red : tanoBlue),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            action.toUpperCase(),
            style: TextStyle(color: isSave ? tanoBlue : Colors.red),
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

/// Whether the current platform uses the Cupertino widgets.
bool _isApple(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

/// Shows a platform-adaptive dialog. [builder] receives the dialog's own
/// context and whether the platform is Apple, and returns the dialog widget
/// (a CupertinoAlertDialog or an AlertDialog). Centralising the
/// showDialog/showCupertinoDialog calls here keeps every feature on the right
/// native widget.
Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext, bool isApple) builder,
  bool barrierDismissible = true,
}) {
  if (_isApple(context)) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) => builder(dialogContext, true),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) => builder(dialogContext, false),
  );
}

/// Shows an adaptive single-field prompt (CupertinoTextField on iOS/macOS, a
/// TextField in a Material dialog elsewhere). Returns the entered text
/// (possibly empty) or null when cancelled.
Future<String?> showAdaptivePrompt({
  required BuildContext context,
  required String title,
  String? message,
  String? hint,
  String? initialValue,
  int? maxLength,
  bool obscureText = false,
  TextInputType? keyboardType,
  String? confirmLabel,
}) async {
  final TextEditingController controller = TextEditingController(
    text: initialValue ?? '',
  );
  final String confirm = confirmLabel ?? AppText.tr('save');

  return showPlatformDialog<String>(
    context: context,
    builder: (BuildContext dialogContext, bool isApple) {
      final Widget field = isApple
          ? CupertinoTextField(
              controller: controller,
              autofocus: true,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLength: maxLength,
              placeholder: hint,
              padding: const EdgeInsets.all(appPaddingTight),
            )
          : TextField(
              controller: controller,
              autofocus: true,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(labelText: hint),
            );
      final Widget content = message == null
          // A small gap between the title and the field, so they do not look
          // glued together when there is no message.
          ? Padding(padding: const EdgeInsets.only(top: appPaddingTight), child: field)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isApple
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Text(message),
                const SizedBox(height: 12.0),
                field,
              ],
            );
      final List<Widget> actions = <Widget>[
        isApple
            ? CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppText.tr('cancel')),
              )
            : TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppText.tr('cancel')),
              ),
        isApple
            ? CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: Text(confirm),
              )
            : TextButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: Text(confirm),
              ),
      ];
      return isApple
          ? CupertinoAlertDialog(
              title: Text(title),
              content: content,
              actions: actions,
            )
          : AlertDialog(
              scrollable: true,
              title: Text(title),
              content: content,
              actions: actions,
            );
    },
  );
}
