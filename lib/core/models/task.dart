/// A task: a checkable item, filed in a note or a project.
///
/// First shape only. The checklist storage, the sync and the board columns
/// come later; this class exists so a card can tell a task from a note.
class Task {
  Task({
    this.id = '',
    this.title = '',
    this.isDone = false,
    this.date = '',
    String? createdAt,
    String? updatedAt,
    this.category = 'nuage',
    this.isImportant = false,
    this.isLocked = false,
    this.isDeleted = false,
    this.deletedAt,
    this.coverImage,
    this.noteId,
    this.projectId,
  })  : createdAt = createdAt ?? date,
        updatedAt = updatedAt ?? date;

  final String id;
  final String title;
  final bool isDone;
  final String date;

  /// When the task was created. Older data has no such column, so it falls
  /// back to [date].
  final String createdAt;

  /// When the task was last modified. Older data has no such column, so it
  /// falls back to [date].
  final String updatedAt;

  final String category;
  final bool isImportant;
  final bool isLocked;
  final bool isDeleted;
  final String? deletedAt;
  final String? coverImage;

  /// Note this task is attached to, when it lives inside one.
  final String? noteId;

  /// Project this task belongs to, when it lives on a board.
  final String? projectId;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        isDone: json['isDone'] == 1,
        date: json['date'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        category: json['category'] as String? ?? 'nuage',
        isImportant: json['isImportant'] == 1,
        isLocked: json['isLocked'] == 1,
        isDeleted: json['isDeleted'] == 1,
        deletedAt: json['deletedAt'] as String?,
        coverImage: json['coverImage'] as String?,
        noteId: json['noteId'] as String?,
        projectId: json['projectId'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'date': date,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'category': category,
        'isImportant': isImportant ? 1 : 0,
        'isLocked': isLocked ? 1 : 0,
        'isDeleted': isDeleted ? 1 : 0,
        'deletedAt': deletedAt,
        'coverImage': coverImage,
        'noteId': noteId,
        'projectId': projectId,
      };

  Task copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? date,
    String? createdAt,
    String? updatedAt,
    String? category,
    bool? isImportant,
    bool? isLocked,
    bool? isDeleted,
    String? deletedAt,
    String? coverImage,
    String? noteId,
    String? projectId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isImportant: isImportant ?? this.isImportant,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      coverImage: coverImage ?? this.coverImage,
      noteId: noteId ?? this.noteId,
      projectId: projectId ?? this.projectId,
    );
  }
}
