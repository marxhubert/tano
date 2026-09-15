import 'package:tano/core/models/note.dart';

/// Sorts notes the way every screen shows them: **bookmarked first**, then the
/// chosen criterion, with the same fallbacks as the home screen.
class NoteSorting {
  const NoteSorting({
    this.by = 'date',
    this.secondaryBy = 'date',
    this.ascending = true,
  });

  final String by;
  final String secondaryBy;
  final bool ascending;

  /// Returns a sorted copy of [notes].
  List<Note> sort(List<Note> notes) => List<Note>.of(notes)..sort(compare);

  int compare(Note note1, Note note2) {
    return compareCards(
      important1: note1.important,
      important2: note2.important,
      by: by,
      secondaryBy: secondaryBy,
      ascending: ascending,
      compare: () => _criterion(note1, note2, by),
      fallback: () => _criterion(note1, note2, secondaryBy),
      dateCompare: () => _criterion(note1, note2, 'date'),
    );
  }

  int _criterion(Note note1, Note note2, String criteria) {
    switch (criteria) {
      case 'alpha':
        return note1.title.toLowerCase().compareTo(note2.title.toLowerCase());
      case 'date':
        return note2.date.compareTo(note1.date);
      case 'updated':
        return note2.updatedAt.compareTo(note1.updatedAt);
      case 'important':
        final int a = note1.important ? 1 : 0;
        final int b = note2.important ? 1 : 0;
        return b.compareTo(a);
      case 'theme':
      case 'category':
        return cardThemeWeight(note1.category)
            .compareTo(cardThemeWeight(note2.category));
      default:
        return 0;
    }
  }
}

/// The card ordering rule, in **one** place: bookmarked cards first, then the
/// main criterion, then the fallback when the criterion ties on important/theme,
/// then the date when neither criterion is the date, finally reversed when
/// [ascending] is false. Shared by notes and folders; only the criterion
/// comparison itself differs per type.
int compareCards({
  required bool important1,
  required bool important2,
  required String by,
  required String secondaryBy,
  required bool ascending,
  required int Function() compare,
  required int Function() fallback,
  required int Function() dateCompare,
}) {
  if (important1 && !important2) return -1;
  if (!important1 && important2) return 1;

  int comparison = compare();
  if (comparison == 0 && (by == 'important' || by == 'theme')) {
    comparison = fallback();
  }
  if (comparison == 0 && by != 'date' && secondaryBy != 'date') {
    comparison = dateCompare();
  }
  return ascending ? comparison : -comparison;
}

/// Sort weight of a card theme, shared by notes and folders.
int cardThemeWeight(String theme) {
  switch (theme) {
    case 'menthe': return 0;
    case 'citron': return 1;
    case 'peche': return 2;
    case 'lavande': return 3;
    case 'rose': return 4;
    case 'azur': return 5;
    case 'sable': return 6;
    case 'sauge': return 7;
    case 'bonbon': return 8;
    case 'nuage':
    default: return 9;
  }
}
