import 'package:tano/core/models/content_entity.dart';
import 'dart:convert';

/// A note, stored locally and (when shared) synchronized peer-to-peer.
///
/// All fields are non-nullable with safe defaults. [createdAt] and [updatedAt]
/// fall back to [date] for data written before those columns existed.
class Note implements ContentEntity {
  @override
  final EntityKind kind;

  bool get isTask => kind == EntityKind.task;
  @override
  String get label => title;
  @override
  bool get isImportant => important;

  Note({
    this.kind = EntityKind.note,
    this.id = '',
    this.title = '',
    this.content = '',
    this.description = '',
    this.date = '',
    String? createdAt,
    String? updatedAt,
    this.important = false,
    this.category = 'nuage',
    this.isDeleted = false,
    this.isLocked = false,
    this.isArchived = false,
    this.deletedAt,
    this.archivedAt,
    this.attachments = const <String>[],
    this.coverImage,
    this.folderId,
  }) : assert(kind == EntityKind.note || kind == EntityKind.task),
       createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  @override
  final String id;
  final String title;
  final String content;
  final String description;
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
  final bool isArchived;
  @override
  final String? deletedAt;

  /// When the document was archived, shown while it stays in the archive.
  @override
  final String? archivedAt;
  @override
  final String? coverImage;

  /// Folder this note is filed in, or null when it is unfiled.
  final String? folderId;

  /// File names (stored under the attachments directory) attached to the
  /// note. Kept as opaque names; the system opens them on demand.
  final List<String> attachments;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    kind: _readKind(json['kind']),
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    description: json['description'] as String? ?? '',
    date: json['date'] as String? ?? '',
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    important: json['important'] == 1,
    category: normalizeCategory(json['category'] as String?),
    isDeleted: json['isDeleted'] == 1,
    isLocked: json['isLocked'] == 1,
    isArchived: json['isArchived'] == 1,
    deletedAt: json['deletedAt'] as String?,
    archivedAt: json['archivedAt'] as String?,
    attachments: _decodeAttachments(json['attachments']),
    coverImage: json['coverImage'] as String?,
    folderId: json['folderId'] as String?,
  );

  static EntityKind _readKind(Object? value) => switch (value) {
    null || 'note' => EntityKind.note,
    'task' => EntityKind.task,
    _ => throw const FormatException('Unsupported document kind'),
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'id': id,
    'title': title,
    'content': content,
    'description': description,
    'date': date,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'important': important ? 1 : 0,
    'category': category,
    'isDeleted': isDeleted ? 1 : 0,
    'isLocked': isLocked ? 1 : 0,
    'isArchived': isArchived ? 1 : 0,
    'deletedAt': deletedAt,
    'archivedAt': archivedAt,
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
    String? description,
    String? date,
    String? createdAt,
    String? updatedAt,
    bool? important,
    String? category,
    bool? isDeleted,
    bool? isLocked,
    bool? isArchived,
    Object? deletedAt = unchangedField,
    Object? archivedAt = unchangedField,
    List<String>? attachments,
    Object? coverImage = unchangedField,
    Object? folderId = unchangedField,
  }) {
    return Note(
      kind: kind,
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      important: important ?? this.important,
      category: category ?? this.category,
      isDeleted: isDeleted ?? this.isDeleted,
      isLocked: isLocked ?? this.isLocked,
      isArchived: isArchived ?? this.isArchived,
      deletedAt: copiedNullable<String>(deletedAt, this.deletedAt),
      archivedAt: copiedNullable<String>(archivedAt, this.archivedAt),
      attachments: attachments ?? this.attachments,
      coverImage: copiedNullable<String>(coverImage, this.coverImage),
      folderId: copiedNullable<String>(folderId, this.folderId),
    );
  }
}
