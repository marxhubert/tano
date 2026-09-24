import 'package:flutter/material.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';

/// Opens the note editor, asking for the system credential first when the
/// caller says the note is protected.
///
/// Home and Folder repeated the same authentication-then-push prologue; only
/// the "is this note protected" rule and what to do with the result stay with
/// the page. [authenticated] carries a credential the page already has (a note
/// opened inside a locked folder); [requiresAuthentication] asks for one now.
/// Returns the editor's [NoteAction], or null when the credential was refused
/// or the route produced nothing.
Future<NoteAction?> openNoteEditor(
  BuildContext context, {
  required bool add,
  required Note note,
  required bool authenticated,
  required bool requiresAuthentication,
  bool fullscreenDialog = false,
  bool readOnly = false,
}) async {
  bool granted = authenticated;
  if (requiresAuthentication) {
    granted = await getIt<AuthService>().authenticate(
      reason: AppText.tr('auth_reason'),
    );
    // The system prompt is awaited: the widget may be gone by now.
    if (!granted || !context.mounted) return null;
  }
  return Navigator.push<NoteAction>(
    context,
    MaterialPageRoute<NoteAction>(
      builder: (BuildContext context) => EditNote(
        add: add,
        noteAction: NoteAction(kind: NoteActionKind.cancel, note: note),
        authenticated: granted,
        readOnly: readOnly,
      ),
      fullscreenDialog: fullscreenDialog,
    ),
  );
}
