import 'package:tano/core/models/content_entity.dart';
import 'package:tano/core/models/note.dart';

/// A checklist document. It uses the same lifecycle and metadata as a note.
class Task extends Note {
  Task({
    super.id,
    super.title,
    super.content,
    super.description,
    super.date,
    super.createdAt,
    super.updatedAt,
    super.important,
    super.category,
    super.isDeleted,
    super.isLocked,
    super.deletedAt,
    super.attachments,
    super.coverImage,
    super.folderId,
  }) : super(kind: EntityKind.task);
}

/// One row of a task document. Blank rows are editor drafts, not saved items.
class TaskItem {
  const TaskItem(this.text, {this.done = false});
  final String text;
  final bool done;

  String get markdown => '- [${done ? 'x' : ' '}] $text';
}

/// The checklist uses the existing note markup, so links and exports share the
/// same representation. Completion sections are a view, not separator data.
class TaskContent {
  static final _marker = RegExp(r'^- \[([ xX])\](?: |$)');

  static List<TaskItem> parse(String content) {
    if (content.isEmpty) return [];
    return content.split('\n').map((line) {
      final match = _marker.firstMatch(line);
      return TaskItem(
        match == null ? line : line.substring(match.end),
        done: match != null && match.group(1)!.toLowerCase() == 'x',
      );
    }).toList();
  }

  static List<TaskItem> savedItems(String content) =>
      parse(content).where((item) => item.text.trim().isNotEmpty).toList();

  static String normalize(String content) => savedItems(content)
      .map((item) => TaskItem(item.text.trim(), done: item.done).markdown)
      .join('\n');

  static String preview(String content) {
    final items = savedItems(content);
    return [
      ...items.where((item) => !item.done),
      ...items.where((item) => item.done),
    ].map((item) => item.markdown).join('\n');
  }
}
