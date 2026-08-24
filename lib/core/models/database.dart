import 'dart:convert';

import 'package:tano/core/models/note.dart';

/// Parses a JSON document into a [NotesJsonData].
NotesJsonData dbFromJson(String str) {
  final Map<String, dynamic> dataFromJson = json.decode(str);
  return NotesJsonData.fromJson(dataFromJson);
}

/// Serializes a [NotesJsonData] to a JSON document.
String dbToJson(NotesJsonData data) {
  final Map<String, dynamic> dataToJson = data.toJson();
  return json.encode(dataToJson);
}

/// In-memory container for the whole note list (Legacy JSON format).
class NotesJsonData {
  List<Note> note;

  NotesJsonData({List<Note>? note}) : note = note ?? [];

  factory NotesJsonData.fromJson(Map<String, dynamic> json) => NotesJsonData(
    note: json['notes'] == null
        ? <Note>[]
        : List<Note>.from(
            (json['notes'] as List).map((dynamic x) => Note.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    'notes': List<dynamic>.from(note.map((dynamic x) => x.toJson())),
  };
}
