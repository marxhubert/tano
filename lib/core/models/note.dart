/// A note, stored locally and (when shared) synchronized peer-to-peer.
///
/// All fields are non-nullable with safe defaults.
class Note {
  const Note({
    this.id = '',
    this.title = '',
    this.content = '',
    this.date = '',
    this.important = false,
    this.category = 'none',
    this.isDeleted = false,
    this.isPinned = false,
    this.isLocked = false,
  });

  final String id;
  final String title;
  final String content;
  final String date;
  final bool important;
  final String category;
  final bool isDeleted;
  final bool isPinned;
  final bool isLocked;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        date: json['date'] as String? ?? '',
        important: json['important'] == 1,
        category: json['category'] as String? ?? 'none',
        isDeleted: json['isDeleted'] == 1,
        isPinned: json['isPinned'] == 1,
        isLocked: json['isLocked'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date,
        'important': important ? 1 : 0,
        'category': category,
        'isDeleted': isDeleted ? 1 : 0,
        'isPinned': isPinned ? 1 : 0,
        'isLocked': isLocked ? 1 : 0,
      };

  /// Returns a copy of this note with the given fields replaced.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    bool? important,
    String? category,
    bool? isDeleted,
    bool? isPinned,
    bool? isLocked,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      important: important ?? this.important,
      category: category ?? this.category,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
