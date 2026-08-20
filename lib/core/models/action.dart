import 'package:tano/core/models/note.dart';

/// What the edit screen did with a note.
enum NoteActionKind { save, delete, cancel }

/// Result returned by the edit screen to its caller (home or search page).
///
/// The previous version used magic strings (`'Save'`, `'Delete'`, `'Cancel'`)
/// which were error-prone; [kind] is now a typed enum.
class NoteAction {
  NoteAction({this.kind = NoteActionKind.cancel, this.note});

  NoteActionKind kind;
  Note? note;
}

