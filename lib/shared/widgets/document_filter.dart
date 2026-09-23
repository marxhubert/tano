import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

enum DocumentFilter {
  all,
  notes,
  tasks;

  /// Whether [note] belongs to this view.
  bool matches(Note note) => switch (this) {
    all => true,
    notes => !note.isTask,
    tasks => note.isTask,
  };

  /// The segment's label: short, and always on screen.
  String get label => AppText.tr(switch (this) {
    all => 'filter_all',
    notes => 'filter_notes',
    tasks => 'filter_tasks',
  });

  /// "1 Note", "0 Task", "3 Docs": the singular holds for zero and one, and
  /// the segment capitalises — the lower-case nouns belong to the metadata
  /// sentences.
  String nounFor(int count) {
    final String noun = AppText.tr(switch (this) {
      all => count <= 1 ? 'doc' : 'docs',
      notes => count <= 1 ? 'note' : 'notes',
      tasks => count <= 1 ? 'task' : 'tasks',
    });
    return noun.isEmpty ? noun : noun[0].toUpperCase() + noun.substring(1);
  }

  /// The word a segment prints: its own name for "All", the kind's noun for the
  /// others.
  String wordFor(int count) =>
      this == DocumentFilter.all ? label : nounFor(count);

  /// The count part of a segment: the total in parentheses for "All", a bare
  /// number for a kind. Both are printed light, so the word stays the label.
  String countText(int count) =>
      this == DocumentFilter.all ? '($count)' : '$count';
}

/// The noun a selection sentence uses. One kind keeps its own name; a selection
/// that mixes kinds is called "docs", the word the "All" segment already uses
/// for every document.
String selectionNounKey({
  required int notes,
  required int tasks,
  required int folders,
}) {
  final int kinds =
      (notes > 0 ? 1 : 0) + (tasks > 0 ? 1 : 0) + (folders > 0 ? 1 : 0);
  if (kinds > 1) return 'doc';
  if (tasks > 0) return 'task';
  if (folders > 0) return 'folder';
  return 'note';
}

/// The plain count of a group: "3 notes", "1 task", "2 folders".
String groupCountLabel({required int total, required String noun}) =>
    '$total ${total > 1 ? AppText.tr('${noun}s') : AppText.tr(noun)}';

/// The sentence a group prints while selecting: "3/5 notes selected", or "All 5
/// notes are selected" when the whole group is taken. A single item keeps the
/// singular wording.
String selectionCountLabel({
  required int count,
  required int total,
  required String noun,
}) {
  if (count > 1) {
    if (count == total) {
      return AppText.tr('all_${noun}s_selected', <String, String>{
        'count': '$count',
      });
    }
    return AppText.tr('${noun}s_selected', <String, String>{
      'count': '$count',
      'total': '$total',
    });
  }
  return AppText.tr('single_${noun}_selected', <String, String>{
    'count': '$count',
  });
}

/// The title of the delete confirmation for [count] selected notes out of the
/// [total] currently shown: taking the whole visible list reads "delete all".
String deleteSelectionTitle({required int count, required int total}) {
  if (count > 1) {
    return count == total
        ? AppText.tr('delete_all_notes')
        : AppText.tr('delete_notes', <String, String>{'count': '$count'});
  }
  return AppText.tr('delete_note');
}

/// The stored filter name, or null for anything unknown.
DocumentFilter? documentFilterFromName(String? name) {
  for (final DocumentFilter filter in DocumentFilter.values) {
    if (filter.name == name) return filter;
  }
  return null;
}

/// The control that switches the document list between every document and one
/// kind at a time: notes, or tasks.
///
/// Every choice keeps its label on screen with its own count, so nothing has to
/// be guessed from an icon and no separate counter is needed. The selected
/// segment takes the accent fill.
class DocumentFilterControl extends StatelessWidget {
  const DocumentFilterControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.countOf,
    this.selectionLabel,
  });

  final DocumentFilter value;
  final ValueChanged<DocumentFilter> onChanged;

  /// How many documents the given view would show right now.
  final int Function(DocumentFilter) countOf;

  /// While something is selected the tags step aside: the control keeps its
  /// container, prints this sentence instead, and wears the active segment's
  /// fill — exactly as if that one tag were chosen.
  final String? selectionLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? sentence = selectionLabel;
    // One kind needs no choice: its own count says everything the three
    // segments would.
    final DocumentFilter? onlyKind = sentence == null ? _onlyKind() : null;
    return SegmentedButton<DocumentFilter>(
      segments: <ButtonSegment<DocumentFilter>>[
        if (sentence != null)
          ButtonSegment<DocumentFilter>(value: value, label: Text(sentence))
        else if (onlyKind != null)
          ButtonSegment<DocumentFilter>(
            value: onlyKind,
            // The only segment is the selected one, whatever the stored filter
            // is, so its number takes the on-accent ink.
            label: _label(
              context,
              onlyKind,
              countOf(onlyKind),
              isSelected: true,
            ),
          )
        else
          for (final DocumentFilter filter in DocumentFilter.values)
            ButtonSegment<DocumentFilter>(
              value: filter,
              label: _label(
                context,
                filter,
                countOf(filter),
                isSelected: filter == value,
              ),
            ),
      ],
      selected: <DocumentFilter>{onlyKind ?? value},
      // The sentence's own segment stays enabled — it wears the active fill —
      // but there is nothing left to choose while selecting, nor when a single
      // kind leaves nothing to switch to.
      onSelectionChanged: sentence != null || onlyKind != null
          ? (Set<DocumentFilter> _) {}
          : (Set<DocumentFilter> selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: paperSecondary(context),
        foregroundColor: primaryTextColor(context),
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: paperRuleColor(context)),
        // The segments with counts have to fit a phone: 12px of padding would
        // wrap the longest label onto a second line.
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        // The theme's control font, not a bare TextStyle: a family-less style
        // would fall back to whatever the platform supplies.
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// The one kind the page holds, or null when it mixes notes and tasks (or
  /// holds none): a single kind has nothing to switch between.
  DocumentFilter? _onlyKind() {
    final bool hasNotes = countOf(DocumentFilter.notes) > 0;
    final bool hasTasks = countOf(DocumentFilter.tasks) > 0;
    if (hasNotes == hasTasks) return null;
    return hasNotes ? DocumentFilter.notes : DocumentFilter.tasks;
  }

  /// "All (33)" and "0 Task": the number and its parentheses take a light
  /// weight and the muted ink, so the noun keeps the segment's own colour —
  /// on-accent when the segment is the selected one.
  Widget _label(
    BuildContext context,
    DocumentFilter filter,
    int count, {
    required bool isSelected,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? light = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: isSelected
          ? scheme.onPrimary.withValues(alpha: .72)
          : mutedTextColor(context),
    );
    final String word = filter.wordFor(count);
    final String number = filter.countText(count);
    // "All" leads with its name, a kind leads with its number.
    final List<TextSpan> spans = filter == DocumentFilter.all
        ? <TextSpan>[
            TextSpan(text: '$word '),
            TextSpan(text: number, style: light),
          ]
        : <TextSpan>[
            TextSpan(text: '$number ', style: light),
            TextSpan(text: word),
          ];
    return Text.rich(TextSpan(children: spans));
  }
}
