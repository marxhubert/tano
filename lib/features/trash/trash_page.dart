import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/trash/trash_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/folder_card_bodies.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/empty_state.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late final TrashViewModel _viewModel;
  bool _isLoading = true;
  // The trash follows the layout chosen for the lists (grid or list).
  bool _isListLayout = false;

  @override
  void initState() {
    super.initState();
    final NotesRepository notes = getIt<NotesRepository>();
    final FoldersRepository folders = notes is FoldersRepository
        ? notes as FoldersRepository
        : const EmptyFoldersRepository();
    _viewModel = TrashViewModel(
      notesRepository: notes,
      foldersRepository: folders,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final bool isList = (prefs.getString('viewLayout') ?? 'gridlist') == 'list';
    await _viewModel.load();
    if (mounted) {
      setState(() {
        _isListLayout = isList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PageScaffold(
          title: AppText.tr('option_recycle_bin'),
          headerMetadata: _headerMetadata,
          // Nothing but the illustration: it must hold its place.
          freezeBody: !_isLoading && _viewModel.isEmpty,
          actions: [
            if (!_viewModel.isEmpty)
              IconButton(
                tooltip: AppText.tr('empty_trash'),
                icon: Icon(
                  Symbols.delete_sweep,
                  color: TanoStates.error.dark,
                  size: 22.0,
                ),
                onPressed: () async {
                  final confirm = await getConfirmation(
                    context: context,
                    actionTitle: AppText.tr('delete_all_notes'),
                    action: AppText.tr('delete'),
                  );
                  if (confirm == true) {
                    await _viewModel.emptyTrash();
                  }
                },
              ),
            // The empty screen has nothing left to do but leave, so the way
            // home sits here, icon only, rather than in the body.
            if (_viewModel.isEmpty)
              IconButton(
                icon: const Icon(Symbols.home),
                tooltip: AppText.tr('home'),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false);
                },
              ),
          ],
          slivers: [
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_viewModel.isEmpty)
              SliverFillRemaining(
                child: emptyState(
                  context,
                  AppText.tr('trash_empty'),
                  image: EmptyArt.bin,
                ),
              )
            else ...<Widget>[
              // Folders first, like on the home page: they keep their content,
              // so their notes are never listed on their own.
              if (_viewModel.deletedFolders.isNotEmpty) ...<Widget>[
                _groupTitle(context, AppText.tr('folders_group')),
                SliverPadding(
                  // The group title already carries the top spacing.
                  padding: const EdgeInsets.fromLTRB(
                    appPaddingMedium,
                    0.0,
                    appPaddingMedium,
                    appPaddingMedium,
                  ),
                  sliver: EntitySliver<Folder>(
                    items: _viewModel.deletedFolders,
                    isList: _isListLayout,
                    // Deleted folders read three to a row in the grid; the list
                    // keeps the shared density.
                    columnCount: _isListLayout ? null : (Size _) => 3,
                    // A folder tile is a perfect square, like on Home.
                    aspectRatio: 1.0,
                    cardBuilder: _folderCard,
                  ),
                ),
              ],
              if (_viewModel.deletedNotes.isNotEmpty) ...<Widget>[
                _groupTitle(context, AppText.tr('notes_group')),
                SliverPadding(
                  // The group title already carries the top spacing.
                  padding: const EdgeInsets.fromLTRB(
                    appPaddingMedium,
                    0.0,
                    appPaddingMedium,
                    appPaddingMedium,
                  ),
                  sliver: EntitySliver<Note>(
                    items: _viewModel.deletedNotes,
                    isList: _isListLayout,
                    cardBuilder: _noteCard,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  /// "1 folder & 3 notes", skipping whichever group is empty.
  String get _headerMetadata {
    final int folders = _viewModel.deletedFolders.length;
    final int notes = _viewModel.deletedNotes.length;
    final List<String> parts = <String>[
      if (folders > 0) _count(folders, 'folder', 'folders'),
      if (notes > 0) _count(notes, 'note', 'notes'),
    ];
    return parts.isEmpty ? AppText.tr('empty') : parts.join(' & ');
  }

  String _count(int count, String singular, String plural) =>
      '$count ${AppText.tr(count > 1 ? plural : singular)}';

  /// A plain group title, like the settings section titles: no underline and
  /// no metadata line, just the label.
  Widget _groupTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          appPaddingLarge,
          appPaddingLarge,
          appPaddingLarge,
          4.0,
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

  Widget _noteCard(BuildContext context, Note note) {
    return Stack(
      children: <Widget>[
        EntityCard(
          kind: note.kind,
          category: note.category,
          title: note.title,
          subtitle: formatNoteDate(note.date),
          coverImage: note.coverImage,
          isImportant: note.important,
          // A locked document stays locked, even in the trash.
          isLocked: note.isLocked,
          // The card must match the sliver layout, or a list card has no
          // intrinsic height and renders nothing.
          isListLayout: _isListLayout,
          // Exactly the normal note body, in either layout.
          builder: (context, textColor, hasCover) => _isListLayout
              ? buildNoteListContent(
                  note: note,
                  textColor: textColor,
                  activeNoteIds: _viewModel.activeNoteIds,
                  hasCover: hasCover,
                )
              : buildNoteGridContent(
                  note: note,
                  textColor: textColor,
                  activeNoteIds: _viewModel.activeNoteIds,
                  hasCover: hasCover,
                ),
        ),
        // The trash's own part: the two actions, always there, locked or not.
        _actions(
          onRestore: () => _viewModel.restoreNote(note.id),
          onDelete: () => _deleteNote(context, note.id),
          textColor: _cardTextColor(context, note.category),
        ),
      ],
    );
  }

  Widget _folderCard(BuildContext context, Folder folder) {
    final int noteCount = _viewModel.noteCountIn(folder.id);
    return Stack(
      children: <Widget>[
        EntityCard(
          kind: EntityKind.folder,
          category: folder.category,
          title: folder.name,
          subtitle: 'x$noteCount',
          subtitleIcon: Symbols.sticky_note_2,
          isImportant: folder.important,
          isLocked: folder.isLocked,
          isListLayout: _isListLayout,
          // Same folder body as the home page.
          builder: (context, textColor, hasCover) => _isListLayout
              ? buildFolderListContent(
                  folder: folder,
                  noteCount: noteCount,
                  textColor: textColor,
                  hasCover: hasCover,
                )
              : buildFolderGridContent(
                  folder: folder,
                  noteCount: noteCount,
                  textColor: textColor,
                  hasCover: hasCover,
                ),
        ),
        _actions(
          onRestore: () => _viewModel.restoreFolder(folder.id),
          onDelete: () => _deleteFolder(context, folder.id),
          textColor: _cardTextColor(context, folder.category),
        ),
      ],
    );
  }

  /// The ink [EntityCard] computes for [category], so the trash actions sit on
  /// the card's own colour whatever the card shows.
  Color _cardTextColor(BuildContext context, String category) => getTextColor(
    themeCategory(category, true, brightness: Theme.of(context).brightness),
  );

  /// The two trash actions, overlaid on a card (on top of its content). The
  /// only difference from a normal card: in a list they sit centred, 8 px above
  /// the bottom edge.
  Widget _actions({
    required VoidCallback onRestore,
    required Future<void> Function() onDelete,
    required Color textColor,
  }) {
    final Widget restore = _TrashAction(
      icon: Symbols.undo,
      onTap: onRestore,
      color: textColor.withValues(alpha: 0.9),
    );
    final Widget delete = _TrashAction(
      icon: Symbols.delete_forever,
      onTap: onDelete,
      color: TanoStates.error.dark,
    );
    if (_isListLayout) {
      return Positioned(
        bottom: 8.0,
        left: 0.0,
        right: 0.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12.0,
          children: <Widget>[restore, delete],
        ),
      );
    }
    return Positioned(
      bottom: 6.0,
      left: 0.0,
      right: 0.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[restore, delete],
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, String id) async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('delete_note'),
      action: AppText.tr('delete'),
    );
    if (confirm == true) await _viewModel.deleteNotePermanently(id);
  }

  Future<void> _deleteFolder(BuildContext context, String id) async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('delete_folder'),
      action: AppText.tr('delete'),
    );
    if (confirm == true) await _viewModel.deleteFolderPermanently(id);
  }
}

class _TrashAction extends StatelessWidget {
  const _TrashAction({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(appPaddingSmall),
        decoration: BoxDecoration(
          color: barColor(context),
          shape: BoxShape.circle,
          // A hairline keeps the dots readable on pale cards.
          border: Border.all(
            color: primaryTextColor(context).withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
