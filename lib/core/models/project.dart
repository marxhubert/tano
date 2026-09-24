import 'package:tano/core/models/content_entity.dart';

/// A project: a board of task columns.
///
/// First shape only. The columns, the ticket ordering and the collaboration
/// come later; this class exists so a card can tell a project from a note.
class Project implements ContentEntity {
  @override
  EntityKind get kind => EntityKind.project;
  @override
  String get label => name;

  Project({
    this.id = '',
    this.name = '',
    this.date = '',
    String? createdAt,
    String? updatedAt,
    this.category = 'nuage',
    this.isImportant = false,
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

  /// When the project was created. Older data has no such column, so it falls
  /// back to [date].
  @override
  final String createdAt;

  /// When the project was last modified. Older data has no such column, so it
  /// falls back to [date].
  @override
  final String updatedAt;

  @override
  final String category;
  @override
  final bool isImportant;
  @override
  final bool isLocked;
  @override
  final bool isDeleted;
  @override
  final String? deletedAt;

  /// A project is not archivable: the archive holds notes and tasks.
  @override
  bool get isArchived => false;
  @override
  String? get archivedAt => null;
  @override
  final String? coverImage;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    date: json['date'] as String? ?? '',
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    category: normalizeCategory(json['category'] as String?),
    isImportant: json['isImportant'] == 1,
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
    'category': category,
    'isImportant': isImportant ? 1 : 0,
    'isLocked': isLocked ? 1 : 0,
    'isDeleted': isDeleted ? 1 : 0,
    'deletedAt': deletedAt,
    'coverImage': coverImage,
  };

  Project copyWith({
    String? id,
    String? name,
    String? date,
    String? createdAt,
    String? updatedAt,
    String? category,
    bool? isImportant,
    bool? isLocked,
    bool? isDeleted,
    Object? deletedAt = unchangedField,
    Object? coverImage = unchangedField,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isImportant: isImportant ?? this.isImportant,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: copiedNullable<String>(deletedAt, this.deletedAt),
      coverImage: copiedNullable<String>(coverImage, this.coverImage),
    );
  }

  Project withoutCover() => copyWith(coverImage: null);
}
