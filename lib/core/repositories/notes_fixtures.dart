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
  // 24 notes distributed across the 7 categories (4/4/4/3/3/3/3).
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
    final int variant = i ~/ categories.length;
    
    // Map the new categories to old titles/contents for now to keep the demo data.
    final String lookupKey = _categoryMap[category] ?? 'neutral';
    
    notes.add(
      Note(
        id: 'fixture-${i + 1}',
        title: _titles[lookupKey]![variant % 4],
        content: _contents[lookupKey]![variant % 4],
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

const Map<String, String> _categoryMap = {
  'neutral': 'none',
  'action': 'work',
  'success': 'note',
  'warning': 'personal',
  'error': 'travel',
  'purple': 'life',
  'yellow': 'project',
  'reference': 'note',
  'subtle': 'personal',
  'archive': 'none',
};

const Map<String, List<String>> _titles = <String, List<String>>{
  'note': <String>[
    'Groceries',
    'Meeting ideas',
    'Book recommendations',
    'Quick reminder',
  ],
  'work': <String>[
    'Project kickoff',
    'Status report',
    'Retro notes',
    'Client follow-up',
  ],
  'personal': <String>[
    'Workout plan',
    'Birthday gift ideas',
    'Weekend plans',
    'New habits',
  ],
  'travel': <String>[
    'Packing list',
    'Itinerary draft',
    'Flight details',
    'Hotel options',
  ],
  'life': <String>[
    'Gratitude list',
    'Goals for the year',
    'Books to read',
    'Morning routine',
  ],
  'project': <String>[
    'Roadmap v1',
    'Feature backlog',
    'Sprint planning',
    'Bug triage',
  ],
  'none': <String>[
    'Random thought',
    'Quote to remember',
    'Wishlist',
    'Misc ideas',
  ],
};

const Map<String, List<String>> _contents = <String, List<String>>{
  'note': <String>[
    'Milk, eggs, bread, coffee beans and something sweet for the weekend.',
    'Brainstorming topics for the next team sync, plus a few open questions.',
    'Three books worth reading this month, starting with the shortest one.',
    'Call the dentist and renew the car insurance before the end of the week.',
  ],
  'work': <String>[
    'Define the scope, agree on milestones and assign owners for each phase.',
    'Summarize what shipped this week and flag the two blocked tasks.',
    'What went well, what to improve, and the actions we commit to.',
    'Prepare the agenda and gather the latest numbers for the call.',
  ],
  'personal': <String>[
    'Monday cardio, Wednesday strength, Friday stretching. Keep it simple.',
    'A watch for dad, a cookbook for mom and flowers for the host.',
    'Saturday market, Sunday hike. Check the weather on Friday.',
    'Read 20 minutes a day and drink more water. Start tomorrow.',
  ],
  'travel': <String>[
    'Passport, charger, adapter, comfortable shoes and a light jacket.',
    'Day one in the old town, day two at the coast, day three back home.',
    'Flight 09:15 outbound, 18:40 return. Check in 24 hours ahead.',
    'Compare the two hotels near the station, breakfast included.',
  ],
  'life': <String>[
    'Good coffee, long walks, music, and the people who make time.',
    'Learn a new skill, travel somewhere new and read more than last year.',
    'One novel, one essay collection and one book about history.',
    'Wake up early, stretch, plan the day and go outside at noon.',
  ],
  'project': <String>[
    'Phase one: core features. Phase two: polish and performance.',
    'Collect ideas from everyone and sort them by impact and effort.',
    'Pick the three stories that unblock the demo and estimate them.',
    'List the recurring bugs and the releases they should land in.',
  ],
  'none': <String>[
    'Sometimes the best ideas come when you are not looking for them.',
    '“Simplicity is the ultimate sophistication.” — Leonardo da Vinci',
    'Noise-cancelling headphones, a new notebook, a plant for the desk.',
    'Notes without a category still deserve a place to live.',
  ],
};
