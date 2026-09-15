import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/trash/trash_view_model.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/config/date_format.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final TrashViewModel _viewModel = TrashViewModel(
    repository: getIt<NotesRepository>(),
  );
  bool _isLoading = true;
  // The trash follows the layout chosen for the lists (grid or list).
  bool _isListLayout = false;

  @override
  void initState() {
    super.initState();
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
          headerMetadata:
              '${_viewModel.deletedNotes.length} ${_viewModel.deletedNotes.length > 1 ? AppText.tr('notes') : AppText.tr('note')}',
          actions: [
            if (!_viewModel.isEmpty)
              IconButton(
                tooltip: AppText.tr('empty_trash'),
                icon: const Icon(
                  Symbols.delete_sweep,
                  color: Color(0xFFFF8A80),
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
          ],
          slivers: [
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_viewModel.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppText.tr('no_note_found')),
                      const SizedBox(height: 16),
                      // Same shape as the "Check for update" action in About:
                      // just an icon and a label, no chrome.
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        icon: Icon(
                          Symbols.in_home_mode,
                          size: 16.0,
                          color: mutedTextColor(context),
                        ),
                        label: Text(
                          AppText.tr('home'),
                          style: TextStyle(
                            color: mutedTextColor(context),
                            fontSize: 14.0,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(appPaddingMedium),
                sliver: EntitySliver<Note>(
                  items: _viewModel.deletedNotes,
                  isList: _isListLayout,
                  cardBuilder: (BuildContext context, Note note) {
                    return EntityCard(
                      kind: EntityKind.note,
                      category: note.category,
                      title: note.title,
                      subtitle: formatNoteDate(note.date),
                      isImportant: note.important,
                      // The card must match the sliver layout, or a list card
                      // has no intrinsic height and renders nothing.
                      isListLayout: _isListLayout,
                      builder: (context, textColor, hasCover) {
                        final Widget restore = _TrashAction(
                          icon: Symbols.undo,
                          onTap: () => _viewModel.restore(note.id),
                          color: textColor.withValues(alpha: 0.9),
                        );
                        final Widget delete = _TrashAction(
                          icon: Symbols.delete_forever,
                          onTap: () async {
                            final confirm = await getConfirmation(
                              context: context,
                              actionTitle: AppText.tr('delete_note'),
                              action: AppText.tr('delete'),
                            );
                            if (confirm == true) {
                              await _viewModel.deletePermanently(note.id);
                            }
                          },
                          color: const Color(0xFFFF8A80),
                        );
                        return SizedBox.expand(
                          child: Stack(
                            children: [
                              // Date and title, kept clear of the actions.
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  8.0,
                                  8.0,
                                  _isListLayout ? 72.0 : 8.0,
                                  8.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4.0,
                                  children: <Widget>[
                                    Text(
                                      formatNoteDate(note.date),
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 8.0,
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      note.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.0,
                                        color: textColor,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (_isListLayout)
                                // List: both actions in the top-right corner,
                                // close together.
                                Positioned(
                                  top: 12.0,
                                  right: 12.0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 12.0,
                                    children: <Widget>[restore, delete],
                                  ),
                                )
                              else
                                // Grid: the actions share the card's bottom.
                                Positioned(
                                  bottom: 6.0,
                                  left: 0.0,
                                  right: 0.0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[restore, delete],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
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
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
