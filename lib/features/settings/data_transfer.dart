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

/// Asks how to export, then writes the `.tano` file where the user chooses.
Future<void> exportData(BuildContext context) async {
  final List<Note> notes = await getIt<NotesRepository>().loadNotes();
  if (!context.mounted) return;
  final int lockedCount = notes.where((Note n) => n.isLocked).length;

  bool encrypted = true;
  String? error;
  final TextEditingController passwordController = TextEditingController();

  final bool? confirmed = await _showExportDialog(
    context,
    passwordController: passwordController,
    isEncrypted: () => encrypted,
    onEncryptedChanged: (bool value) => encrypted = value,
    error: () => error,
    onErrorChanged: (String? value) => error = value,
    hasLockedNotes: lockedCount > 0,
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

Future<bool?> _showExportDialog(
  BuildContext context, {
  required TextEditingController passwordController,
  required bool Function() isEncrypted,
  required ValueChanged<bool> onEncryptedChanged,
  required String? Function() error,
  required ValueChanged<String?> onErrorChanged,
  required bool hasLockedNotes,
}) {
  return showPlatformDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext, bool isApple) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        final bool encrypted = isEncrypted();
        final List<Widget> content = <Widget>[
          if (isApple)
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
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppText.tr('export_encrypt')),
              value: encrypted,
              onChanged: (bool value) => setDialogState(() {
                onEncryptedChanged(value);
                onErrorChanged(null);
              }),
            ),
          if (encrypted) ...<Widget>[
            if (isApple) ...<Widget>[
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
            ] else
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppText.tr('export_password'),
                  helperText: AppText.tr('export_password_hint'),
                  errorText: error(),
                ),
              ),
          ] else ...<Widget>[
            if (isApple) const SizedBox(height: 8.0),
            Text(
              AppText.tr('import_clear_warning'),
              style: const TextStyle(fontSize: 12.0),
            ),
            if (hasLockedNotes) ...<Widget>[
              if (!isApple) const SizedBox(height: 8.0),
              Text(
                AppText.tr('export_locked_warning'),
                style: TextStyle(
                  fontSize: 12.0,
                  color: isApple
                      ? CupertinoColors.systemRed
                      : const Color(0xFFE57373),
                ),
              ),
            ],
          ],
        ];

        void onExport() {
          if (isEncrypted() && passwordController.text.length < 8) {
            setDialogState(
              () => onErrorChanged(AppText.tr('password_too_short')),
            );
            return;
          }
          Navigator.pop(dialogContext, true);
        }

        final Widget body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isApple ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          children: content,
        );
        return isApple
            ? CupertinoAlertDialog(
                title: Text(AppText.tr('export_data')),
                content: body,
                actions: <Widget>[
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(AppText.tr('cancel')),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: onExport,
                    child: Text(AppText.tr('export_action')),
                  ),
                ],
              )
            : AlertDialog(
                title: Text(AppText.tr('export_data')),
                content: body,
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(AppText.tr('cancel')),
                  ),
                  TextButton(
                    onPressed: onExport,
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
  return showAdaptivePrompt(
    context: context,
    title: AppText.tr('import_password_title'),
    message: AppText.tr('import_password_message'),
    hint: AppText.tr('export_password'),
    obscureText: true,
    confirmLabel: AppText.tr('ok'),
  );
}
