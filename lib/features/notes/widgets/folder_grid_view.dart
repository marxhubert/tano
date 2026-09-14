import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/folder_card_bodies.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Grid of folder cards, one card per folder.
class FolderGridView extends StatelessWidget {
  const FolderGridView({
    super.key,
    required this.viewModel,
    required this.onOpenFolder,
  });

  final HomeViewModel viewModel;
  final void Function(Folder folder) onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final List<Folder> folders = viewModel.folders;
    return SliverGrid.count(
      crossAxisCount: gridCrossAxisCount(context),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      childAspectRatio: 0.9,
      children: List<Widget>.generate(folders.length, (int index) {
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
          builder: (context, textColor, hasCover) => buildFolderGridContent(
            folder: folder,
            noteCount: noteCount,
            textColor: textColor,
            hasCover: hasCover,
          ),
        );
      }),
    );
  }
}
