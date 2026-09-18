import 'package:tano/core/models/content_entity.dart';
import 'dart:convert';

/// A note, stored locally and (when shared) synchronized peer-to-peer.
///
/// All fields are non-nullable with safe defaults. [createdAt] and [updatedAt]
/// fall back to [date] for data written before those columns existed.
class Note implements ContentEntity {
  @override
  EntityKind get kind => EntityKind.note;
  @override
  String get label => title;
  @override
  bool get isImportant => important;

  Note({
    this.id = '',
    this.title = '',
    this.content = '',
    this.date = '',
    String? createdAt,
    String? updatedAt,
    this.important = false,
    this.category = 'nuage',
    this.isDeleted = false,
    this.isLocked = false,
    this.deletedAt,
    this.attachments = const <String>[],
    this.coverImage,
    this.folderId,
  }) : createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  @override
  final String id;
  final String title;
  final String content;
  @override
  final String date;

  /// When the note was created. Older data has no such column, so it falls
  /// back to [date].
  @override
  final String createdAt;

  /// When the note was last modified. Older data has no such column, so it
  /// falls back to [date].
  @override
  final String updatedAt;

  final bool important;
  @override
  final String category;
  @override
  final bool isDeleted;
  @override
  final bool isLocked;
  @override
  final String? deletedAt;
  @override
  final String? coverImage;

  /// Folder this note is filed in, or null when it is unfiled.
  final String? folderId;

  /// File names (stored under the attachments directory) attached to the
  /// note. Kept as opaque names; the system opens them on demand.
  final List<String> attachments;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    date: json['date'] as String? ?? '',
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    important: json['important'] == 1,
    category: normalizeCategory(json['category'] as String?),
    isDeleted: json['isDeleted'] == 1,
    isLocked: json['isLocked'] == 1,
    deletedAt: json['deletedAt'] as String?,
    attachments: _decodeAttachments(json['attachments']),
    coverImage: json['coverImage'] as String?,
    folderId: json['folderId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'important': important ? 1 : 0,
    'category': category,
    'isDeleted': isDeleted ? 1 : 0,
    'isLocked': isLocked ? 1 : 0,
    'deletedAt': deletedAt,
    'attachments': jsonEncode(attachments),
    'coverImage': coverImage,
    'folderId': folderId,
  };

  /// Canonical category name for uncategorized notes ('nuage' pastel).
  static const String defaultCategory = 'nuage';

  /// Decodes the JSON-encoded attachments column into a list of names.
  static List<String> _decodeAttachments(Object? value) {
    if (value is String && value.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.whereType<String>().toList();
        }
      } on FormatException {
        // Ignore malformed legacy values and fall back to no attachments.
      }
    }
    return const <String>[];
  }

  /// Normalizes legacy category values ('none', 'neutral', empty) to the
  /// canonical [defaultCategory].

  /// Returns this note with no folder (used when a folder is deleted).
  Note withoutFolder() => copyWith(folderId: null);

  /// Returns a copy of this note with the given fields replaced.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? createdAt,
    String? updatedAt,
    bool? important,
    String? category,
    bool? isDeleted,
    bool? isLocked,
    Object? deletedAt = unchangedField,
    List<String>? attachments,
    Object? coverImage = unchangedField,
    Object? folderId = unchangedField,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      important: important ?? this.important,
      category: category ?? this.category,
      isDeleted: isDeleted ?? this.isDeleted,
      isLocked: isLocked ?? this.isLocked,
      deletedAt: copiedNullable<String>(deletedAt, this.deletedAt),
      attachments: attachments ?? this.attachments,
      coverImage: copiedNullable<String>(coverImage, this.coverImage),
      folderId: copiedNullable<String>(folderId, this.folderId),
    );
  }
}
