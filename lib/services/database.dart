import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:tano/models/note.dart';

// DbFileRoutines class
class DbFileRoutines {
    Future<String> get _localPath async {
        final directory = await getApplicationDocumentsDirectory();
        return directory.path;
    }

    Future<File> get _localFile async {
        final path = await _localPath;
        return File('$path/local_persistence.json');
    }

    Future<String> readNotes() async {
        try {
            final file = await _localFile;
            if (!file.existsSync()) {
                debugPrint("File does not exist: ${file.absolute}");
                await writeNotes('{"notes": []}');
            }
            String contents = await file.readAsString();
            return contents;
        } catch(e) {
            debugPrint("Error readNotes: $e");
            return "";
        }
    }

    Future<File> writeNotes(String json) async {
        final file = await _localFile;
        return file.writeAsString(json);
    }
}

// To read and parse form json data
Database dbFromJson(String str) {
    final dataFromJson = json.decode(str);
    return Database.fromJson(dataFromJson);
}

// To save and parse to json data
String dbToJson(Database data) {
    final dataToJson = data.toJson();
    return json.encode(dataToJson);
}

// Database class
class Database {
    List<Note> note;

    Database({
        List<Note>? note,
    }) : note = note ?? [];

    factory Database.fromJson(Map<String, dynamic> json) => Database(
        note: json["notes"] == null
            ? <Note>[]
            : List<Note>.from((json["notes"] as List).map((x) => Note.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "notes": List<dynamic>.from(note.map((x) => x.toJson())),
    };
}
