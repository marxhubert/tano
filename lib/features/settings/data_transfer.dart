import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/confirm.dart';

bool _isApple(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

/// Asks how to export, then writes the `.tano` file where the user chooses.
Future<void> exportData(BuildContext context) async {
  final List<Note> notes = await getIt<NotesRepository>().loadNotes();
  if (!context.mounted) return;
  final int lockedCount = notes.where((Note n) => n.isLocked).length;

  bool encrypted = true;
  String? error;
  final TextEditingController passwordController = TextEditingController();

  final bool? confirmed = _isApple(context)
      ? await _showCupertinoExportDialog(
          context,
          lockedCount: lockedCount,
          passwordController: passwordController,
          isEncrypted: () => encrypted,
          onEncryptedChanged: (bool value) => encrypted = value,
          error: () => error,
          onErrorChanged: (String? value) => error = value,
          hasLockedNotes: lockedCount > 0,
        )
      : await _showMaterialExportDialog(
          context,
          lockedCount: lockedCount,
          passwordController: passwordController,
          isEncrypted: () => encrypted,
          onEncryptedChanged: (bool value) => encrypted = value,
          error: () => error,
          onErrorChanged: (String? value) => error = value,
        );

  if (confirmed != true || !context.mounted) return;

  final Uint8List bytes = await ExportService().build(
    notes: notes,
    password: encrypted ? passwordController.text : null,
    unlockLockedNotes: !encrypted,
  );
  final String stamp = DateTime.now().toIso8601String().split('T').first;
  await FilePicker.saveFile(
    fileName: 'tanonote-$stamp.tano',
    bytes: bytes,
    mimeType: 'application/octet-stream',
  );
  if (context.mounted) {
    showAdaptiveNotice(context, AppText.tr('export_done'));
  }
}

Future<bool?> _showCupertinoExportDialog(
  BuildContext context, {
  required int lockedCount,
  required TextEditingController passwordController,
  required bool Function() isEncrypted,
  required ValueChanged<bool> onEncryptedChanged,
  required String? Function() error,
  required ValueChanged<String?> onErrorChanged,
  required bool hasLockedNotes,
}) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        final bool encrypted = isEncrypted();
        return CupertinoAlertDialog(
          title: Text(AppText.tr('export_data')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(AppText.tr('export_encrypt'))),
                  CupertinoSwitch(
                    value: encrypted,
                    onChanged: (bool value) => setDialogState(() {
                      onEncryptedChanged(value);
                      onErrorChanged(null);
                    }),
                  ),
                ],
              ),
              if (encrypted) ...<Widget>[
                const SizedBox(height: 8.0),
                CupertinoTextField(
                  controller: passwordController,
                  obscureText: true,
                  placeholder: AppText.tr('export_password'),
                  padding: const EdgeInsets.all(8.0),
                ),
                if (error() != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      error()!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ] else ...<Widget>[
                const SizedBox(height: 8.0),
                Text(
                  AppText.tr('import_clear_warning'),
                  style: const TextStyle(fontSize: 12.0),
                ),
                if (hasLockedNotes)
                  Text(
                    AppText.tr('export_locked_warning'),
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
              ],
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppText.tr('cancel')),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (isEncrypted() && passwordController.text.length < 8) {
                  setDialogState(
                    () => onErrorChanged(AppText.tr('password_too_short')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(AppText.tr('export_action')),
            ),
          ],
        );
      },
    ),
  );
}

Future<bool?> _showMaterialExportDialog(
  BuildContext context, {
  required int lockedCount,
  required TextEditingController passwordController,
  required bool Function() isEncrypted,
  required ValueChanged<bool> onEncryptedChanged,
  required String? Function() error,
  required ValueChanged<String?> onErrorChanged,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        final bool encrypted = isEncrypted();
        return AlertDialog(
          title: Text(AppText.tr('export_data')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppText.tr('export_encrypt')),
                value: encrypted,
                onChanged: (bool value) => setDialogState(() {
                  onEncryptedChanged(value);
                  onErrorChanged(null);
                }),
              ),
              if (encrypted)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppText.tr('export_password'),
                    helperText: AppText.tr('export_password_hint'),
                    errorText: error(),
                  ),
                )
              else ...<Widget>[
                Text(
                  AppText.tr('import_clear_warning'),
                  style: const TextStyle(fontSize: 12.0),
                ),
                if (lockedCount > 0) ...<Widget>[
                  const SizedBox(height: 8.0),
                  Text(
                    AppText.tr('export_locked_warning'),
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFFE57373),
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppText.tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                if (isEncrypted() && passwordController.text.length < 8) {
                  setDialogState(
                    () => onErrorChanged(AppText.tr('password_too_short')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(AppText.tr('export_action')),
            ),
          ],
        );
      },
    ),
  );
}

/// Picks a `.tano` file, asks for its password when needed, then merges it.
Future<void> importData(BuildContext context) async {
  final PlatformFile? file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: <String>['tano'],
  );
  final String? path = file?.path;
  if (path == null || !context.mounted) return;

  final Uint8List data = await File(path).readAsBytes();
  if (!context.mounted) return;

  String? password;
  if (ImportService.isEncrypted(data)) {
    password = await showImportPasswordDialog(context);
    if (password == null || password.isEmpty) return;
  }

  if (!context.mounted) return;
  try {
    final ImportResult result = await ImportService(
      repository: getIt<NotesRepository>(),
    ).import(data, password: password);
    if (!context.mounted) return;
    showAdaptiveNotice(
      context,
      AppText.tr('import_done', <String, String>{
        'added': '${result.added}',
        'skipped': '${result.skipped}',
        'unlocked': '${result.unlocked}',
      }),
    );
  } on ImportException catch (error) {
    if (!context.mounted) return;
    showAdaptiveAlert(
      context: context,
      title: AppText.tr('import_failed'),
      message: error.message,
    );
  }
}

/// Asks for the password of an encrypted export, with a native look per
/// platform (Cupertino on iOS, Material elsewhere).
Future<String?> showImportPasswordDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();

  if (_isApple(context)) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(AppText.tr('import_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(AppText.tr('import_password_message')),
            const SizedBox(height: 12.0),
            CupertinoTextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              placeholder: AppText.tr('export_password'),
              padding: const EdgeInsets.all(8.0),
            ),
          ],
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.tr('cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(AppText.tr('ok')),
          ),
        ],
      ),
    );
  }

  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(AppText.tr('import_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(AppText.tr('import_password_message')),
            const SizedBox(height: 12.0),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppText.tr('export_password'),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(AppText.tr('ok')),
          ),
        ],
      );
    },
  );
}
