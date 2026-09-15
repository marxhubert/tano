/// A folder grouping notes.
///
/// It carries the same organisational attributes as a note (favourite, theme,
/// lock, trash) but no content of its own.
class Folder {
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
  })  : createdAt = createdAt ?? date,
        updatedAt = updatedAt ?? date;

  final String id;
  final String name;
  final String date;

  /// When the folder was created. Older data has no such column, so it falls
  /// back to [date].
  final String createdAt;

  /// When the folder was last modified. Older data has no such column, so it
  /// falls back to [date].
  final String updatedAt;

  final bool important;
  final String category;
  final bool isLocked;
  final bool isDeleted;
  final String? deletedAt;

  /// Optional cover image file name, displayed on the folder card.
  final String? coverImage;

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        important: json['important'] == 1,
        category: _normalizeCategory(json['category'] as String?),
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

  static String _normalizeCategory(String? value) {
    if (value == null || value.isEmpty || value == 'none' || value == 'neutral') {
      return defaultCategory;
    }
    return value;
  }

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
    String? deletedAt,
    String? coverImage,
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
      deletedAt: deletedAt ?? this.deletedAt,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  /// Returns a copy of this folder without its cover image.
  ///
  /// [copyWith] cannot clear the nullable [coverImage] field, so removing the
  /// cover goes through this explicit copy.
  Folder withoutCover() {
    return Folder(
      id: id,
      name: name,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      important: important,
      category: category,
      isLocked: isLocked,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }
}
