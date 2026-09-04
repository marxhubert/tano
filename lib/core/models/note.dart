import 'dart:convert';

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
    this.category = 'nuage',
    this.isDeleted = false,
    this.isPinned = false,
    this.isLocked = false,
    this.deletedAt,
    this.attachments = const <String>[],
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
  final String? deletedAt;

  /// File names (stored under the attachments directory) attached to the
  /// note. Kept as opaque names; the system opens them on demand.
  final List<String> attachments;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        date: json['date'] as String? ?? '',
        important: json['important'] == 1,
        category: _normalizeCategory(json['category'] as String?),
        isDeleted: json['isDeleted'] == 1,
        isPinned: json['isPinned'] == 1,
        isLocked: json['isLocked'] == 1,
        deletedAt: json['deletedAt'] as String?,
        attachments: _decodeAttachments(json['attachments']),
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
        'deletedAt': deletedAt,
        'attachments': jsonEncode(attachments),
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
  static String _normalizeCategory(String? value) {
    if (value == null || value.isEmpty || value == 'none' || value == 'neutral') {
      return defaultCategory;
    }
    return value;
  }

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
    String? deletedAt,
    List<String>? attachments,
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
      deletedAt: deletedAt ?? this.deletedAt,
      attachments: attachments ?? this.attachments,
    );
  }
}
