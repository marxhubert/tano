import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
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
    return EntitySliver<Folder>(
      items: viewModel.folders,
      isList: true,
      cardBuilder: (BuildContext context, Folder folder) => _card(folder),
    );
  }

  Widget _card(Folder folder) {
    final int noteCount = viewModel.noteCountIn(folder.id);
    return EntityCard(
      kind: EntityKind.folder,
      category: folder.category,
      title: folder.name,
      subtitle: 'x$noteCount',
      subtitleIcon: Symbols.description,
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
  }
}
