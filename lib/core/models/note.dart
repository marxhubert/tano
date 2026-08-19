/// A note, stored locally and (when shared) synchronized peer-to-peer.
///
/// All fields are non-nullable with safe defaults: the previous version used
/// nullable fields everywhere, which forced `?? ''` / `?? false` and risky
/// `!` operators across the codebase.
class Note {
  const Note({
    this.id = '',
    this.title = '',
    this.content = '',
    this.date = '',
    this.important = false,
    this.category = 'none',
  });

  final String id;
  final String title;
  final String content;
  final String date;
  final bool important;
  final String category;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    date: json['date'] as String? ?? '',
    important: json['important'] == 1,
    category: json['category'] as String? ?? 'none',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date,
    'important': important ? 1 : 0,
    'category': category,
  };

  /// Returns a copy of this note with the given fields replaced.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    bool? important,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      important: important ?? this.important,
      category: category ?? this.category,
    );
  }
}

