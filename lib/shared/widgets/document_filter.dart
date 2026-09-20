import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/theme.dart';

enum DocumentFilter {
  all,
  notes,
  tasks;

  bool matches(Note note) => switch (this) {
    all => true,
    notes => !note.isTask,
    tasks => note.isTask,
  };
  String get label => AppText.tr(switch (this) {
    all => 'all_docs',
    notes => 'all_notes',
    tasks => 'all_tasks',
  });
  /// "1 note", "0 task", "3 docs": the singular holds for zero and one.
  String countLabel(int count) =>
      '$count ${AppText.tr(switch (this) {
        all => count <= 1 ? 'doc' : 'docs',
        notes => count <= 1 ? 'note' : 'notes',
        tasks => count <= 1 ? 'task' : 'tasks',
      })}';

  /// What the list says when this filter hides everything.
  String get emptyLabel => AppText.tr(switch (this) {
    all => 'no_docs_found',
    notes => 'no_notes_found',
    tasks => 'no_tasks_found',
  });
}

/// The style of the active filter's label. Shared so the title line above a
/// note list can put its metadata on the same baseline.
TextStyle documentFilterLabelStyle(BuildContext context) =>
    sectionTitleStyle(context).copyWith(fontSize: 20);

class DocumentFilterButtons extends StatelessWidget {
  const DocumentFilterButtons({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final DocumentFilter value;
  final ValueChanged<DocumentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = isDark
        ? TanoStates.action.dark
        : TanoStates.action.light;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // One shared baseline: this is what lets the title line set its metadata
      // on the active label's line, and the glyphs on that same line.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 24,
      children: [
        for (final filter in DocumentFilter.values)
          Flexible(
            child: Semantics(
              button: true,
              selected: filter == value,
              label: filter.label,
              child: Tooltip(
                message: filter.label,
                child: InkWell(
                  onTap: () => onChanged(filter),
                  // A little air keeps a comfortable tap target.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: filter == value
                        ? Text(
                            filter.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: documentFilterLabelStyle(context),
                          )
                        // Nudged down: baseline-aligned, a glyph's ink sits a
                        // touch high next to the label.
                        : Transform.translate(
                            offset: const Offset(0.0, 2.0),
                            child: Icon(
                              switch (filter) {
                                DocumentFilter.all => Symbols.dashboard,
                                DocumentFilter.notes => Symbols.sticky_note_2,
                                DocumentFilter.tasks =>
                                  Symbols.format_list_bulleted,
                              },
                              size: 20,
                              color: primary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
