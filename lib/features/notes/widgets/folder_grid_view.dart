import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/folder_card.dart';
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
        return FolderCard(
          folder: folder,
          noteCount: viewModel.noteCountIn(folder.id),
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
        );
      }),
    );
  }
}
