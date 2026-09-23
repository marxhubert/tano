import 'package:tano/core/models/note_access_policy.dart';
import 'package:tano/core/models/folder.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/archive_validation.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Asks how to export, then writes the `.tano` file where the user chooses.
Future<void> exportData(BuildContext context) async {
  final repository = getIt<NotesRepository>();
  final folders = repository is FoldersRepository
      ? await (repository as FoldersRepository).loadFolders()
      : <Folder>[];
  final access = NoteAccessPolicy(folders);
  final List<Note> notes = (await repository.loadNotes())
      .where(access.isReachable)
      .map(
        (note) => access.requiresAuthentication(note)
            ? note.copyWith(isLocked: true)
            : note,
      )
      .toList();
  if (notes.any((note) => note.isLocked)) {
    if (!await getIt<AuthService>().authenticate()) return;
  }
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

  final password = passwordController.text;
  passwordController.dispose();
  if (confirmed != true || !context.mounted) return;

  final Uint8List bytes;
  try {
    bytes = await ExportService().build(
      notes: notes,
      password: encrypted ? password : null,
    );
  } on ExportException catch (error) {
    if (context.mounted) {
      showAdaptiveAlert(
        context: context,
        title: AppText.tr('export_failed'),
        message: error.message,
      );
    }
    return;
  }
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
        // A locked note must never land in a cleartext file, so the switch is
        // frozen on as soon as the selection contains one.
        void setEncrypted(bool value) => setDialogState(() {
          onEncryptedChanged(value);
          onErrorChanged(null);
        });
        final List<Widget> content = <Widget>[
          if (isApple)
            Row(
              children: <Widget>[
                Expanded(child: Text(AppText.tr('export_encrypt'))),
                CupertinoSwitch(
                  value: encrypted,
                  onChanged: hasLockedNotes ? null : setEncrypted,
                ),
              ],
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppText.tr('export_encrypt')),
              value: encrypted,
              onChanged: hasLockedNotes ? null : setEncrypted,
            ),
          if (encrypted) ...<Widget>[
            if (isApple) ...<Widget>[
              const SizedBox(height: appPaddingTight),
              CupertinoTextField(
                controller: passwordController,
                obscureText: true,
                placeholder: AppText.tr('export_password'),
                padding: const EdgeInsets.all(appPaddingTight),
              ),
              if (error() != null)
                Padding(
                  padding: const EdgeInsets.only(top: appPaddingSmall),
                  child: Text(
                    error()!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: TanoText.tiny,
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
            if (isApple) const SizedBox(height: appPaddingTight),
            Text(
              AppText.tr('import_clear_warning'),
              style: const TextStyle(fontSize: TanoText.tiny),
            ),
          ],
          if (hasLockedNotes) ...<Widget>[
            if (!isApple) const SizedBox(height: appPaddingTight),
            Text(
              AppText.tr('export_locked_required'),
              style: TextStyle(
                fontSize: TanoText.tiny,
                color: isApple
                    ? CupertinoColors.systemRed
                    : TanoStates.error.dark,
              ),
            ),
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
          crossAxisAlignment: isApple
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
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

  if (await File(path).length() > ArchiveValidation.maxArchiveBytes) {
    if (context.mounted) {
      showAdaptiveAlert(
        context: context,
        title: AppText.tr('import_failed'),
        message: AppText.tr('import_too_large'),
      );
    }
    return;
  }
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
