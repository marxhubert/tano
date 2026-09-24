import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';

/// Runs a storage write and reports a recoverable failure instead of letting it
/// escape to the framework.
///
/// Returns true only when [operation] completed. On failure it shows the same
/// data-preserving message everywhere, and the caller decides what to roll back
/// or reload. The editor, Home and a folder all persist through this, so a
/// failed write reads the same on every screen.
Future<bool> runStorageOperation(
  BuildContext context,
  Future<void> Function() operation, {
  String? title,
  String? message,
}) async {
  try {
    await operation();
    return true;
  } catch (_) {
    if (context.mounted) {
      await showAdaptiveAlert(
        context: context,
        title: title ?? AppText.tr('load_error_title'),
        message: message ?? AppText.tr('storage_recovery_message'),
      );
    }
    return false;
  }
}
