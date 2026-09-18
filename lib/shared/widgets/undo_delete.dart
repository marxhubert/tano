import 'package:flutter/material.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';

/// The one way to offer an undo after a deletion.
///
/// The same words, the same gesture and the same restore on every screen: the
/// home and a folder page both delete, and both must be able to take it back.
Future<void> showUndoDelete(
  BuildContext context, {
  required NotesRepository repository,
  required DeletedBatch batch,
  required Future<void> Function() onRestored,
}) {
  // The message reflects what was actually removed: notes, folders, or both.
  final List<String> parts = <String>[
    if (batch.folders.isNotEmpty)
      AppText.count(batch.folders.length, 'folder', 'folders'),
    if (batch.notes.isNotEmpty)
      AppText.count(batch.notes.length, 'note', 'notes'),
  ];

  return showAdaptiveNoticeWithAction(
    context: context,
    message: parts.isEmpty
        ? AppText.tr('note_deleted')
        : '${parts.join(' & ')} ${AppText.tr('deleted')}',
    actionLabel: AppText.tr('undo'),
    onAction: () async {
      await batch.restoreInStorage(repository);
      await onRestored();
    },
  );
}
