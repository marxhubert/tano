import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';

void main() {
  test('fixture tasks are short checklists, some long and some described', () {
    final TanoFixtures fixtures = buildFixtures(canLock: false);
    final List<Note> tasks = fixtures.notes
        .where((Note n) => n.isTask)
        .toList();
    expect(tasks, isNotEmpty);

    int longLists = 0;
    int described = 0;
    for (final Note task in tasks) {
      final List<TaskItem> items = TaskContent.savedItems(task.content);
      expect(items, isNotEmpty, reason: task.id);
      for (final TaskItem item in items) {
        // A task row never runs past the 250-character limit; the long note
        // paragraph the fixtures once shared would land here as one giant row.
        expect(
          item.text.length,
          lessThanOrEqualTo(250),
          reason: '${task.id}: ${item.text}',
        );
      }
      if (items.length >= 26) longLists++;
      if (task.description.isNotEmpty) described++;
    }

    // "Beaucoup de tasks" and "avec description": both shapes exist.
    expect(longLists, greaterThan(0));
    expect(described, greaterThan(0));
  });
}
