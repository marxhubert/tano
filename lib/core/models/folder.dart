import 'package:tano/core/models/content_entity.dart';

/// A folder grouping notes.
///
/// It carries the same organisational attributes as a note (favourite, theme,
/// lock, trash) but no content of its own.
class Folder implements ContentEntity {
  @override
  EntityKind get kind => EntityKind.folder;
  @override
  String get label => name;
  @override
  bool get isImportant => important;

  Folder({
    this.id = '',
    this.name = '',
    this.date = '',
    String? createdAt,
    String? updatedAt,
    this.important = false,
    this.category = 'nuage',
    this.isLocked = false,
    this.isDeleted = false,
    this.deletedAt,
    this.coverImage,
  }) : createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  @override
  final String id;
  final String name;
  @override
  final String date;

  /// When the folder was created. Older data has no such column, so it falls
  /// back to [date].
  @override
  final String createdAt;

  /// When the folder was last modified. Older data has no such column, so it
  /// falls back to [date].
  @override
  final String updatedAt;

  final bool important;
  @override
  final String category;
  @override
  final bool isLocked;
  @override
  final bool isDeleted;
  @override
  final String? deletedAt;

  /// A folder cannot be archived: the archive holds documents only.
  @override
  bool get isArchived => false;
  @override
  String? get archivedAt => null;

  /// Optional cover image file name, displayed on the folder card.
  @override
  final String? coverImage;

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    date: json['date'] as String? ?? '',
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    important: json['important'] == 1,
    category: normalizeCategory(json['category'] as String?),
    isLocked: json['isLocked'] == 1,
    isDeleted: json['isDeleted'] == 1,
    deletedAt: json['deletedAt'] as String?,
    coverImage: json['coverImage'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'date': date,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'important': important ? 1 : 0,
    'category': category,
    'isLocked': isLocked ? 1 : 0,
    'isDeleted': isDeleted ? 1 : 0,
    'deletedAt': deletedAt,
    'coverImage': coverImage,
  };

  static const String defaultCategory = 'nuage';

  Folder copyWith({
    String? id,
    String? name,
    String? date,
    String? createdAt,
    String? updatedAt,
    bool? important,
    String? category,
    bool? isLocked,
    bool? isDeleted,
    Object? deletedAt = unchangedField,
    Object? coverImage = unchangedField,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      important: important ?? this.important,
      category: category ?? this.category,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: copiedNullable<String>(deletedAt, this.deletedAt),
      coverImage: copiedNullable<String>(coverImage, this.coverImage),
    );
  }

  Folder withoutCover() => copyWith(coverImage: null);
}
