import 'dart:math';
import 'package:tano/core/models/note.dart';

/// Builds a demo note list seeded with 36 notes using the new theme system.
List<Note> buildNotesFixtures() {
  final List<Note> notes = <Note>[];
  final DateTime baseDate = DateTime.now();
  final Random random = Random(42); // Fixed seed for reproducible fixtures

  final List<String> themes = [
    'menthe', 'citron', 'peche', 'lavande', 'rose',
    'azur', 'sable', 'sauge', 'bonbon', 'nuage'
  ];

  // 1. First pass: Create the 36 notes
  for (int i = 0; i < 36; i++) {
    final String theme = themes[i % themes.length];
    final int variant = (i ~/ themes.length) % 4;

    notes.add(
      Note(
        id: 'fixture-${i + 1}',
        title: _titles[theme]?[variant] ?? 'Note ${i + 1}',
        content: '', // Will be filled in second pass
        date: baseDate.subtract(Duration(days: i * 6 + (i % 3))).toString(),
        important: i % 3 == 0,
        isPinned: random.nextDouble() > 0.8, // ~20% of notes are pinned
        category: theme,
      ),
    );
  }

  // 2. Second pass: Fill content with text, random links and checklists
  for (int i = 0; i < notes.length; i++) {
    final StringBuffer contentBuffer = StringBuffer();
    
    // Add some random text
    contentBuffer.write(_generateLongText(i));

    // Randomly add a link to another note (excluding self)
    if (random.nextBool()) {
      int targetIdx;
      do {
        targetIdx = random.nextInt(notes.length);
      } while (targetIdx == i);
      
      final targetNote = notes[targetIdx];
      contentBuffer.write('\n\nSee also: [[${targetNote.id}:${targetNote.title}]]');
    }

    // Randomly add a second link
    if (random.nextDouble() > 0.8) {
       int targetIdx;
      do {
        targetIdx = random.nextInt(notes.length);
      } while (targetIdx == i);
      
      final targetNote = notes[targetIdx];
      contentBuffer.write('\nCheck this: [[${targetNote.id}:${targetNote.title}]]');
    }

    // Randomly add a checklist
    if (random.nextDouble() > 0.6) {
      contentBuffer.write('\n\n## Tasks\n');
      final int taskCount = 2 + random.nextInt(4);
      for (int t = 0; t < taskCount; t++) {
        final bool checked = random.nextBool();
        contentBuffer.write('- [${checked ? 'x' : ' '}] Task ${t + 1} for ${notes[i].title}\n');
      }
    }

    notes[i] = notes[i].copyWith(content: contentBuffer.toString());
  }

  return notes;
}

/// Generates a dummy text of approximately 100 to 200 words (shorter than before for better UX with many notes).
String _generateLongText(int seed) {
  final List<String> words = [
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit',
    'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et', 'dolore',
    'magna', 'aliqua', 'ut', 'enim', 'ad', 'minim', 'veniam', 'quis', 'nostrud',
    'exercitation', 'ullamco', 'laboris', 'nisi', 'ut', 'aliquip', 'ex', 'ea',
    'commodo', 'consequat', 'duis', 'aute', 'irure', 'dolor', 'in', 'reprehenderit',
    'in', 'voluptate', 'velit', 'esse', 'cillum', 'dolore', 'eu', 'fugiat', 'nulla',
    'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident',
    'sunt', 'in', 'culpa', 'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est',
    'laborum', 'tano', 'note', 'productivity', 'organization', 'kanban', 'project',
    'management', 'flexible', 'simple', 'clean', 'workspace', 'design', 'modern',
    'efficiency', 'workflow', 'checklist', 'ideas', 'collaboration', 'structure'
  ];

  final int wordCount = 100 + (seed * 17) % 100;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < wordCount; i++) {
    final String word = words[(seed + i * i) % words.length];
    if (i == 0) {
      buffer.write(word[0].toUpperCase() + word.substring(1));
    } else {
      buffer.write(word);
    }
    
    if (i > 0 && i % 12 == 0) {
      buffer.write('. ');
      if (i + 1 < wordCount) {
        final String nextWord = words[(seed + (i + 1) * (i + 1)) % words.length];
        buffer.write(nextWord[0].toUpperCase() + nextWord.substring(1));
        i++;
      }
    } else if (i % 7 == 0) {
      buffer.write(', ');
    } else {
      buffer.write(' ');
    }
  }

  if (!buffer.toString().endsWith('. ')) {
    buffer.write('.');
  }

  return buffer.toString();
}

const Map<String, List<String>> _titles = <String, List<String>>{
  'menthe': ['Project Kickoff', 'Status Report', 'Retro Notes', 'Client Follow-up'],
  'citron': ['Brainstorming', 'New Feature Idea', 'Product Roadmap', 'Market Analysis'],
  'peche': ['Workout Plan', 'Birthday Gift Ideas', 'Weekend Plans', 'New Habits'],
  'lavande': ['Design Review', 'UI Research', 'User Feedback', 'Style Guide'],
  'rose': ['Urgent Fixes', 'Bug Triage', 'Critical Issues', 'Hotfix Roadmap'],
  'azur': ['Documentation', 'External Links', 'Tech Stack', 'API Specs'],
  'sable': ['Minor Tasks', 'Backlog Refinement', 'Cleanup', 'Low Priority'],
  'sauge': ['Groceries', 'Meeting Ideas', 'Book Recommendations', 'Quick Reminder'],
  'bonbon': ['Inspiration', 'Moodboard', 'Creative Session', 'Artistic Drafts'],
  'nuage': ['Random Thought', 'Misc Ideas', 'Quote to Remember', 'Wishlist'],
};
