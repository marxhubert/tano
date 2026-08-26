import 'dart:convert';

import 'package:tano/core/models/note.dart';

/// Decodes a legacy JSON document (`{"notes": [...]}`) into a list of notes.
///
/// Returns an empty list when the document is missing the `notes` key.
/// Malformed JSON rethrows the underlying [FormatException] so callers can
/// surface an explicit error instead of silently treating it as "no data".
List<Note> decodeNotes(String source) {
  final Object? decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    return <Note>[];
  }
  final Object? notes = decoded['notes'];
  if (notes is! List) {
    return <Note>[];
  }
  return notes
      .map((dynamic x) => Note.fromJson(x as Map<String, dynamic>))
      .toList();
}

/// Encodes a list of notes into the legacy JSON document format
/// (`{"notes": [...]}`).
String encodeNotes(List<Note> notes) {
  return jsonEncode(<String, dynamic>{
    'notes': notes.map((Note note) => note.toJson()).toList(),
  });
}
