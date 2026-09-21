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

  /// What the list says when this filter hides everything.
  String get emptyLabel => AppText.tr(switch (this) {
    all => 'no_docs_found',
    notes => 'no_notes_found',
    tasks => 'no_tasks_found',
  });
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
  });

  final DocumentFilter value;
  final ValueChanged<DocumentFilter> onChanged;

  /// How many documents the given view would show right now.
  final int Function(DocumentFilter) countOf;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SegmentedButton<DocumentFilter>(
      segments: <ButtonSegment<DocumentFilter>>[
        for (final DocumentFilter filter in DocumentFilter.values)
          ButtonSegment<DocumentFilter>(
            value: filter,
            label: _label(context, filter, countOf(filter)),
          ),
      ],
      selected: <DocumentFilter>{value},
      onSelectionChanged: (Set<DocumentFilter> selection) =>
          onChanged(selection.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: paperSecondary(context),
        foregroundColor: primaryTextColor(context),
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: paperRuleColor(context)),
        // Four segments with counts have to fit a phone: 12px of padding would
        // wrap "Projects" onto a second line.
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

  /// "All (33)" and "0 Task": the number and its parentheses take a light
  /// weight and the muted ink, so the noun keeps the segment's own colour —
  /// on-accent when the segment is the selected one.
  Widget _label(BuildContext context, DocumentFilter filter, int count) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isSelected = filter == value;
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
