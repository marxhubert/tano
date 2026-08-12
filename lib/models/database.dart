import 'dart:convert';

import 'package:tano/models/note.dart';

/// Parses a JSON document into a [Database].
Database dbFromJson(String str) {
    final Map<String, dynamic> dataFromJson = json.decode(str);
    return Database.fromJson(dataFromJson);
}

/// Serializes a [Database] to a JSON document.
String dbToJson(Database data) {
    final Map<String, dynamic> dataToJson = data.toJson();
    return json.encode(dataToJson);
}

/// In-memory container for the whole note list.
class Database {
    List<Note> note;

    Database({
        List<Note>? note,
    }) : note = note ?? [];

    factory Database.fromJson(Map<String, dynamic> json) => Database(
        note: json['notes'] == null
            ? <Note>[]
            : List<Note>.from((json['notes'] as List).map((dynamic x) => Note.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        'notes': List<dynamic>.from(note.map((dynamic x) => x.toJson())),
    };
}
