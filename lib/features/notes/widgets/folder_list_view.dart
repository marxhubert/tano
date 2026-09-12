import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/folder_card.dart';

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
        return FolderCard(
          folder: folder,
          noteCount: viewModel.noteCountIn(folder.id),
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
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8.0),
    );
  }
}
