import 'package:tano/core/models/note.dart';

/// Builds a demo note list seeded with 24 notes.
///
/// The notes cover every category, span a wide range of dates spread
/// over the past months, and mix favorite (`important`) and regular
/// notes so every list layout, sort order and selection mode can be
/// exercised.
List<Note> buildNotesFixtures() {
  final List<Note> notes = <Note>[];
  final DateTime baseDate = DateTime.now();
  // 24 notes distributed across the 10 categories.
  final List<String> categories = <String>[
    'neutral',
    'action',
    'success',
    'warning',
    'error',
    'purple',
    'yellow',
    'reference',
    'subtle',
    'archive',
  ];

  for (int i = 0; i < 24; i++) {
    final String category = categories[i % categories.length];
    final int variant = (i ~/ categories.length) % 4;

    // Use a long text for every note to test large contents (300-500 words).
    final String longContent = _generateLongText(i);

    notes.add(
      Note(
        id: 'fixture-${i + 1}',
        title: _titles[category]?[variant] ?? 'Note ${i + 1}',
        content: longContent,
        // Different dates: 6 days apart, plus a small offset so
        // no two notes share the exact same timestamp.
        date: baseDate.subtract(Duration(days: i * 6 + (i % 3))).toString(),
        // Roughly one third of the notes are favorites.
        important: i % 3 == 0,
        category: category,
      ),
    );
  }

  return notes;
}

/// Generates a dummy text of approximately 300 to 500 words.
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

  final int wordCount = 300 + (seed * 17) % 200; // wordCount between 300 and 500
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < wordCount; i++) {
    final String word = words[(seed + i * i) % words.length];
    if (i == 0) {
      buffer.write(word[0].toUpperCase() + word.substring(1));
    } else {
      buffer.write(word);
    }
    
    // Add punctuation periodically
    if (i > 0 && i % 12 == 0) {
      buffer.write('. ');
      if (i + 1 < wordCount) {
        final String nextWord = words[(seed + (i + 1) * (i + 1)) % words.length];
        buffer.write(nextWord[0].toUpperCase() + nextWord.substring(1));
        i++; // skip next since we just wrote it
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
  'neutral': ['Random Thought', 'Misc Ideas', 'Quote to Remember', 'Wishlist'],
  'action': ['Project Kickoff', 'Status Report', 'Retro Notes', 'Client Follow-up'],
  'success': ['Groceries', 'Meeting Ideas', 'Book Recommendations', 'Quick Reminder'],
  'warning': ['Workout Plan', 'Birthday Gift Ideas', 'Weekend Plans', 'New Habits'],
  'error': ['Urgent Fixes', 'Bug Triage', 'Critical Issues', 'Hotfix Roadmap'],
  'purple': ['Design Review', 'UI Research', 'User Feedback', 'Style Guide'],
  'yellow': ['Brainstorming', 'New Feature Idea', 'Product Roadmap', 'Market Analysis'],
  'reference': ['Documentation', 'External Links', 'Tech Stack', 'API Specs'],
  'subtle': ['Minor Tasks', 'Backlog Refinement', 'Cleanup', 'Low Priority'],
  'archive': ['Old Archive', 'Past Sprint', 'Legacy Notes', 'Drafts'],
};
