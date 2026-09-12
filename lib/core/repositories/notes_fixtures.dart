import 'dart:math';

import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';

/// Folders and notes generated for the demo fixtures.
class TanoFixtures {
  const TanoFixtures({required this.folders, required this.notes});

  final List<Folder> folders;
  final List<Note> notes;
}

const List<String> _themes = <String>[
  'menthe',
  'citron',
  'peche',
  'lavande',
  'rose',
  'azur',
  'sable',
  'sauge',
  'bonbon',
  'nuage',
];

const List<String> _folderNames = <String>[
  'Work',
  'Personal',
  'Ideas',
  'Archive',
  'Empty',
];

/// Builds the demo fixtures:
///
/// - 5 folders, 4 of them holding 15 to 27 notes and one left empty;
/// - 33 notes that are not filed in any folder;
/// - random pin/bookmark/theme on every folder and note; exactly 2 folders
///   are locked (never the empty one), and no pinned or bookmarked note is
///   locked;
/// - 3 to 12 inserted notes and 1 to 3 checklists (each with a title and 6 to
///   15 items) on the notes that are not deliberately "empty";
/// - a 450 to 630 word text on every note.
///
/// The generator uses a fixed seed so the whole set stays reproducible.
TanoFixtures buildFixtures() {
  final Random random = Random(42);
  final DateTime baseDate = DateTime.now();

  // --- Folders -------------------------------------------------------------
  // Exactly 2 folders are locked; the 3 others, including the empty one, stay
  // unlocked.
  final List<bool> folderLocks = <bool>[true, true, false, false]
    ..shuffle(random);
  final List<Folder> folders = <Folder>[
    for (int i = 0; i < 5; i++)
      Folder(
        id: 'folder-${i + 1}',
        name: _folderNames[i],
        date: baseDate.subtract(Duration(minutes: i)).toString(),
        important: random.nextBool(),
        category: _themes[random.nextInt(_themes.length)],
        isPinned: random.nextBool(),
        isLocked: i < 4 && folderLocks[i],
      ),
  ];

  // 4 filled folders (15..27 notes) and one empty folder.
  final List<int> folderSizes = <int>[
    for (int i = 0; i < 4; i++) 15 + random.nextInt(13),
  ];
  final int folderNoteTotal = folderSizes.fold<int>(0, (int a, int b) => a + b);

  // --- Flag plans ----------------------------------------------------------
  // Folders: 3 pinned (also bookmarked), 6 bookmarked in total, and only 3
  // locked notes; a locked note never carries pin or bookmark. 10 notes have
  // nothing but their text and theme.
  final List<_Spec> folderSpecs = <_Spec>[
    // The 3 pinned notes are also bookmarked and never locked.
    ...List<_Spec>.generate(3, (_) => const _Spec(pin: true, lock: false, mark: true)),
    // 3 more bookmarked notes, never locked.
    ...List<_Spec>.generate(3, (_) => const _Spec(pin: false, lock: false, mark: true)),
    // Only 3 locked notes, none of them pinned or bookmarked.
    ...List<_Spec>.generate(3, (_) => const _Spec(pin: false, lock: true, mark: false)),
    // 10 notes with nothing but their text and theme.
    ...List<_Spec>.generate(
      10,
      (_) => const _Spec(pin: false, lock: false, mark: false, empty: true),
    ),
    // The remaining folder notes are clean too.
    ...List<_Spec>.generate(
      folderNoteTotal - 19,
      (_) => const _Spec(pin: false, lock: false, mark: false),
    ),
  ]..shuffle(random);

  // Unfiled: 6 pinned (also bookmarked), 9 bookmarked in total, and only 9
  // locked notes; a locked note never carries pin or bookmark. 15 notes have
  // no flag at all, 12 of them completely empty.
  final List<_Spec> looseSpecs = <_Spec>[
    // The 6 pinned notes are also bookmarked and never locked.
    ...List<_Spec>.generate(6, (_) => const _Spec(pin: true, lock: false, mark: true)),
    // 3 more bookmarked notes, never locked.
    ...List<_Spec>.generate(3, (_) => const _Spec(pin: false, lock: false, mark: true)),
    // Only 9 locked notes, none of them pinned or bookmarked.
    ...List<_Spec>.generate(9, (_) => const _Spec(pin: false, lock: true, mark: false)),
    // 12 notes with nothing but their text and theme.
    ...List<_Spec>.generate(
      12,
      (_) => const _Spec(pin: false, lock: false, mark: false, empty: true),
    ),
    // 3 more clean notes (with insertions/checklists, no flags).
    ...List<_Spec>.generate(3, (_) => const _Spec(pin: false, lock: false, mark: false)),
  ]..shuffle(random);

  // --- Plans ---------------------------------------------------------------
  final List<_Plan> plans = <_Plan>[];
  int folderCursor = 0;
  for (int f = 0; f < 4; f++) {
    for (int n = 0; n < folderSizes[f]; n++) {
      plans.add(
        _plan(
          random,
          folders[f].id,
          folderSpecs[folderCursor++],
          baseDate,
          plans.length,
        ),
      );
    }
  }
  for (int n = 0; n < 33; n++) {
    plans.add(_plan(random, null, looseSpecs[n], baseDate, plans.length));
  }

  final List<Note> notes = <Note>[
    for (int i = 0; i < plans.length; i++)
      Note(
        id: 'fixture-${i + 1}',
        title: plans[i].title,
        content: '',
        date: plans[i].date,
        important: plans[i].spec.mark,
        category: plans[i].category,
        isPinned: plans[i].spec.pin,
        isLocked: plans[i].spec.lock,
        folderId: plans[i].folderId,
      ),
  ];

  // --- Content -------------------------------------------------------------
  for (int i = 0; i < notes.length; i++) {
    final _Spec spec = plans[i].spec;
    final StringBuffer content = StringBuffer(_generateText(random));

    if (!spec.empty) {
      // 3 to 12 inserted notes.
      final int links = 3 + random.nextInt(10);
      for (int l = 0; l < links; l++) {
        int target = random.nextInt(notes.length);
        if (target == i) target = (target + 1) % notes.length;
        content.write(
          '\n\nSee also: [[${notes[target].id}:${notes[target].title}]]',
        );
      }

      // 1 to 3 checklists, each made of a title and 6 to 15 items.
      final int checklists = 1 + random.nextInt(3);
      for (int c = 0; c < checklists; c++) {
        final String title =
            _checklistTitles[random.nextInt(_checklistTitles.length)];
        content.write('\n\n## $title ${c + 1}\n');
        final int items = 6 + random.nextInt(10);
        for (int it = 0; it < items; it++) {
          final String verb =
              _taskVerbs[random.nextInt(_taskVerbs.length)];
          content.write('- [${random.nextBool() ? 'x' : ' '}] $verb ${it + 1}\n');
        }
      }
    }

    notes[i] = notes[i].copyWith(content: content.toString());
  }

  return TanoFixtures(folders: folders, notes: notes);
}

/// Convenience wrapper for the callers that only need the notes.
List<Note> buildNotesFixtures() => buildFixtures().notes;

/// Convenience wrapper for the callers that only need the folders.
List<Folder> buildFoldersFixtures() => buildFixtures().folders;

_Plan _plan(
  Random random,
  String? folderId,
  _Spec spec,
  DateTime baseDate,
  int index,
) {
  final String theme = _themes[random.nextInt(_themes.length)];
  final List<String> titles = _titles[theme] ?? const <String>['Note'];
  return _Plan(
    folderId: folderId,
    spec: spec,
    category: theme,
    title: '${titles[random.nextInt(titles.length)]} ${index + 1}',
    date: baseDate.subtract(Duration(minutes: index)).toString(),
  );
}

/// Builds a text whose length is between 450 and 630 words.
String _generateText(Random random) {
  const int min = 450;
  const int max = 630;
  final int target = min + random.nextInt(max - min + 1);
  final StringBuffer buffer = StringBuffer();
  int count = 0;

  while (count < target) {
    if (buffer.isNotEmpty) buffer.write(' ');
    final int sentence = 6 + random.nextInt(9);
    for (int i = 0; i < sentence && count < target; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(_words[random.nextInt(_words.length)]);
      count++;
    }
    buffer.write('.');
  }

  final String text = buffer.toString();
  return text[0].toUpperCase() + text.substring(1);
}

/// Flag combination of a generated note.
class _Spec {
  const _Spec({
    required this.pin,
    required this.lock,
    required this.mark,
    this.empty = false,
  });

  final bool pin;
  final bool lock;
  final bool mark;

  /// A note that has nothing but its text and its colour theme.
  final bool empty;
}

/// A generated note, before its content is filled in.
class _Plan {
  const _Plan({
    required this.folderId,
    required this.spec,
    required this.category,
    required this.title,
    required this.date,
  });

  final String? folderId;
  final _Spec spec;
  final String category;
  final String title;
  final String date;
}

const List<String> _checklistTitles = <String>[
  'Tasks',
  'To do',
  'Steps',
  'Checklist',
  'Follow-up',
];

const List<String> _taskVerbs = <String>[
  'Review',
  'Draft',
  'Validate',
  'Send',
  'Clean up',
  'Prepare',
  'Schedule',
  'Document',
  'Test',
  'Deploy',
];

const List<String> _words = <String>[
  'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
  'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
  'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam', 'quis',
  'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'aliquip', 'ex',
  'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure', 'in', 'reprehenderit',
  'voluptate', 'velit', 'esse', 'cillum', 'eu', 'fugiat', 'nulla', 'pariatur',
  'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident', 'sunt',
  'culpa', 'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est',
  'laborum', 'tano', 'note', 'productivity', 'organization', 'kanban',
  'project', 'management', 'flexible', 'simple', 'clean', 'workspace',
  'design', 'modern', 'efficiency', 'workflow', 'checklist', 'ideas',
  'collaboration', 'structure', 'focus', 'clarity', 'routine', 'habits',
];

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
