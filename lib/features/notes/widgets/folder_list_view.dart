import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/folder_card_bodies.dart';

/// List of folder rows.
class FolderListView extends StatelessWidget {
  const FolderListView({
    super.key,
    required this.viewModel,
    required this.onOpenFolder,
  });

  final HomeViewModel viewModel;
  final void Function(Folder folder) onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final List<Folder> folders = viewModel.folders;
    return SliverList.separated(
      itemCount: folders.length,
      itemBuilder: (BuildContext context, int index) {
        final Folder folder = folders[index];
        final int noteCount = viewModel.noteCountIn(folder.id);
        return EntityCard(
          kind: EntityKind.folder,
          category: folder.category,
          title: folder.name,
          subtitle: 'x$noteCount',
          subtitleIcon: Icons.description_outlined,
          coverImage: folder.coverImage,
          isPinned: folder.isPinned,
          isImportant: folder.important,
          isLocked: folder.isLocked,
          isSelectable: !folder.isLocked,
          isListLayout: true,
          isSelected: viewModel.selected.contains(folder.id),
          isInSelectionMode: viewModel.isInSelectionMode,
          onTap: () {
            if (viewModel.isInSelectionMode) {
              viewModel.toggleSelection(folder.id);
            } else {
              onOpenFolder(folder);
            }
          },
          onLongPress: () => viewModel.enterSelectionMode(folder.id),
          onSelectionToggle: () => viewModel.toggleSelection(folder.id),
          builder: (context, textColor, hasCover) => buildFolderListContent(
            folder: folder,
            noteCount: noteCount,
            textColor: textColor,
            hasCover: hasCover,
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8.0),
    );
  }
}
