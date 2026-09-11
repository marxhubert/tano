/// A folder grouping notes.
///
/// It carries the same organisational attributes as a note (favourite, theme,
/// pin, trash) but no content of its own.
class Folder {
  const Folder({
    this.id = '',
    this.name = '',
    this.date = '',
    this.important = false,
    this.category = 'nuage',
    this.isPinned = false,
    this.isLocked = false,
    this.isDeleted = false,
    this.deletedAt,
    this.coverImage,
  });

  final String id;
  final String name;
  final String date;
  final bool important;
  final String category;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final String? deletedAt;

  /// Optional cover image file name, displayed on the folder card.
  final String? coverImage;

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        important: json['important'] == 1,
        category: _normalizeCategory(json['category'] as String?),
        isPinned: json['isPinned'] == 1,
        isLocked: json['isLocked'] == 1,
        isDeleted: json['isDeleted'] == 1,
        deletedAt: json['deletedAt'] as String?,
        coverImage: json['coverImage'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'date': date,
        'important': important ? 1 : 0,
        'category': category,
        'isPinned': isPinned ? 1 : 0,
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
    bool? important,
    String? category,
    bool? isPinned,
    bool? isLocked,
    bool? isDeleted,
    String? deletedAt,
    String? coverImage,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      important: important ?? this.important,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      coverImage: coverImage ?? this.coverImage,
    );
  }
}
