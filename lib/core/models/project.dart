/// A project: a board of task columns.
///
/// First shape only. The columns, the ticket ordering and the collaboration
/// come later; this class exists so a card can tell a project from a note.
class Project {
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
  })  : createdAt = createdAt ?? date,
        updatedAt = updatedAt ?? date;

  final String id;
  final String name;
  final String date;

  /// When the project was created. Older data has no such column, so it falls
  /// back to [date].
  final String createdAt;

  /// When the project was last modified. Older data has no such column, so it
  /// falls back to [date].
  final String updatedAt;

  final String category;
  final bool isImportant;
  final bool isLocked;
  final bool isDeleted;
  final String? deletedAt;
  final String? coverImage;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        category: json['category'] as String? ?? 'nuage',
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
    String? deletedAt,
    String? coverImage,
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
      deletedAt: deletedAt ?? this.deletedAt,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  /// Returns a copy of this project without its cover image.
  ///
  /// [copyWith] cannot clear the nullable [coverImage] field, so removing the
  /// cover goes through this explicit copy.
  Project withoutCover() {
    return Project(
      id: id,
      name: name,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      category: category,
      isImportant: isImportant,
      isLocked: isLocked,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }
}
