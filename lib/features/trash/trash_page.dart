import 'package:flutter/material.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/trash/trash_view_model.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/note_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _viewModel.load();
    if (mounted) {
      setState(() {
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
          headerTrailing: Text(
            '${_viewModel.deletedNotes.length} ${_viewModel.deletedNotes.length > 1 ? AppText.tr('notes') : AppText.tr('note')}',
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          ),
          actions: [
            if (!_viewModel.isEmpty)
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep, 
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
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (_viewModel.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppText.tr('no_note_found')),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/home',
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home, size: 20),
                        label: Text(AppText.tr('home')),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryTextColor(context),
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(appPaddingMedium),
                sliver: SliverGrid.count(
                  crossAxisCount: gridCrossAxisCount(context),
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.0,
                  children: List.generate(_viewModel.deletedNotes.length, (index) {
                    final note = _viewModel.deletedNotes[index];
                    return NoteCard(
                      note: note,
                      builder: (context, textColor) => SizedBox.expand(
                        child: Stack(
                          children: [
                            // Background Content (Date & Title only)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4.0,
                                children: <Widget>[
                                  Padding(
                                    padding: note.isPinned 
                                      ? const EdgeInsets.only(left: 8.0)
                                      : const EdgeInsets.only(left: 0.0),
                                    child: Text(
                                      formatNoteDate(note.date),
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 8.0,
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                            // Floating Actions
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _TrashAction(
                                    icon: Icons.restore,
                                    onTap: () => _viewModel.restore(note.id),
                                    color: textColor.withValues(alpha: 0.9),
                                  ),
                                  _TrashAction(
                                    icon: Icons.delete_forever,
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
