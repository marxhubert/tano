import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';

/// A sandbox for the card designs, ahead of the task and project entities.
///
/// Tasks and projects do not exist yet, so they are simulated with notes: the
/// same [EntityCard] and the same note bodies, only the titles (and the counts
/// in the content) differ. The two layouts are shown one after the other so a
/// single screen compares them.
class LabPage extends StatelessWidget {
  const LabPage({super.key});

  /// Two of each future kind, so grid and list can be compared.
  static final List<Note> _samples = <Note>[
    Note(
      id: 'note-1',
      title: 'Note 1',
      content: 'Idées en vrac pour la semaine.',
      date: '2026-02-01 09:00:00.000',
      category: 'menthe',
    ),
    Note(
      id: 'note-2',
      title: 'Note 2',
      content: 'Compte rendu de la réunion design.',
      date: '2026-02-02 14:30:00.000',
      category: 'citron',
    ),
    Note(
      id: 'task-1',
      title: 'Task 1',
      content: '- [ ] Maquette\n- [x] Spécifications',
      date: '2026-02-03 08:00:00.000',
      category: 'azur',
    ),
    Note(
      id: 'task-2',
      title: 'Task 2',
      content: '- [x] Tests\n- [ ] Mise en production',
      date: '2026-02-04 08:00:00.000',
      category: 'lavande',
    ),
    Note(
      id: 'project-1',
      title: 'Project 1',
      content: 'Kanban en préparation.',
      date: '2026-02-05 08:00:00.000',
      category: 'peche',
      attachments: <String>['brief.pdf'],
    ),
    Note(
      id: 'project-2',
      title: 'Project 2',
      content: 'En cours de cadrage.',
      date: '2026-02-06 08:00:00.000',
      category: 'rose',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Labo',
      actions: const <Widget>[ThemeToggleButton()],
      slivers: <Widget>[
        const _SectionTitle('Grid'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: appPaddingMedium),
          sliver: EntitySliver<Note>(
            items: _samples,
            isList: false,
            cardBuilder: (BuildContext context, Note note) =>
                _card(note, false),
          ),
        ),
        const _SectionTitle('List'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: appPaddingMedium),
          sliver: EntitySliver<Note>(
            items: _samples,
            isList: true,
            cardBuilder: (BuildContext context, Note note) => _card(note, true),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24.0)),
      ],
    );
  }

  Widget _card(Note note, bool isList) {
    // The entity type drives the watermark; the samples are still notes.
    final EntityKind kind = note.id.startsWith('task-')
        ? EntityKind.task
        : note.id.startsWith('project-')
        ? EntityKind.project
        : EntityKind.note;
    return EntityCard(
      kind: kind,
      category: note.category,
      title: note.title,
      subtitle: formatNoteDate(note.date),
      coverImage: note.coverImage,
      isImportant: note.important,
      isListLayout: isList,
      builder: (context, textColor, hasCover) => isList
          ? buildNoteListContent(
              note: note,
              textColor: textColor,
              activeNoteIds: const <String>{},
              hasCover: hasCover,
            )
          : buildNoteGridContent(
              note: note,
              textColor: textColor,
              activeNoteIds: const <String>{},
              hasCover: hasCover,
            ),
    );
  }
}

/// A plain group title, like the settings section titles.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          appPaddingLarge,
          appPaddingLarge,
          appPaddingLarge,
          appPaddingSmall,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: mutedTextColor(context),
            fontWeight: FontWeight.bold,
            fontSize: TanoText.listTitle,
            letterSpacing: -0.08,
          ),
        ),
      ),
    );
  }
}
