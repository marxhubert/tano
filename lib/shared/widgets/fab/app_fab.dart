import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

part 'fab_bars.dart';
part 'fab_items.dart';
part 'fab_menus.dart';

enum FabVerticalMenu { none, add, color, more, link, move }

enum ListSortCriteria { date, title }

/// The surface colour of an open FAB menu: the FAB primary darkened, so the
/// menu and the action cell that opened it can share the exact same tone.
Color _fabMenuSurface(BuildContext context) =>
    Color.lerp(Theme.of(context).colorScheme.primary, Colors.black, 0.15)!;

/// The unified FAB that morphs between various states (Home, Search, Selection, Editor).
class AppFab extends StatefulWidget {
  const AppFab({
    super.key,
    this.isSearchMode = false,
    this.isSelectionMode = false,
    this.canMove = true,
    this.canDelete = true,
    this.isEditorMode = false,
    this.isFolderMode = false,
    this.isTitleEditing = false,
    this.collapsedByDefault = false,
    this.onAddNote,
    this.isFindMode = false,
    this.findCurrent = 0,
    this.findTotal = 0,
    this.isAddMode = false,
    this.isImportant = false,
    this.isLocked = false,
    this.controller,
    this.focusNode,
    this.onAdd,
    this.onAddFolder,
    this.onSearchChanged,
    this.onReset,
    this.onDelete,
    this.onClearSelection,
    this.onSelectAll,
    this.onSave,
    this.onColorLens,
    this.onMore,
    this.onColorSelected,
    this.currentCategory,
    this.currentNoteId,
    this.currentFolderId,
    this.onImageSelected,
    this.onChecklistSelected,
    this.onLinkSelected,
    this.onNoteLinkSelected,
    this.onAttachmentSelected,
    this.onImportantSelected,
    this.onFindSelected,
    this.onFindPrev,
    this.onFindNext,
    this.onFindReset,
    this.onMoveTo,
    this.onLockSelected,
    this.onDeleteSelected,
    this.onEditTitle,
  });

  final bool isSearchMode;
  final bool isSelectionMode;

  /// Selection mode: whether the "move" action is available. It is refused as
  /// soon as a folder is part of the selection.
  final bool canMove;

  /// Selection mode: whether the "delete" action is available. It is refused
  /// when nothing is selected.
  final bool canDelete;
  final bool isEditorMode;

  /// Folder page: the add menu offers a cover and a new note, the more menu
  /// offers bookmark, edit, lock and delete.
  final bool isFolderMode;

  /// Folder page: the title is being renamed, so the FAB stays reduced.
  final bool isTitleEditing;

  /// When true, the FAB rests in its reduced (circular) form, unless the user
  /// explicitly expands it. Used when the folder list can scroll.
  final bool collapsedByDefault;

  /// Folder page: creates a note inside the folder.
  final VoidCallback? onAddNote;
  final bool isFindMode;
  final int findCurrent;
  final int findTotal;
  final bool isAddMode;
  final bool isImportant;
  final bool isLocked;
  final String? currentNoteId;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onAdd;

  /// Home screen: creates a new folder.
  final VoidCallback? onAddFolder;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;
  final VoidCallback? onClearSelection;
  final VoidCallback? onSelectAll;
  final VoidCallback? onSave;
  final VoidCallback? onColorLens;
  final VoidCallback? onMore;
  final ValueChanged<String>? onColorSelected;
  final String? currentCategory;
  final VoidCallback? onImageSelected;
  final VoidCallback? onChecklistSelected;
  final VoidCallback? onLinkSelected;
  final ValueChanged<Note>? onNoteLinkSelected;
  final VoidCallback? onAttachmentSelected;
  final VoidCallback? onImportantSelected;
  final VoidCallback? onFindSelected;
  final VoidCallback? onFindPrev;
  final VoidCallback? onFindNext;
  final VoidCallback? onFindReset;
  /// The folder excluded from the move targets (the note's or the folder
  /// page's own folder). Null on home.
  final String? currentFolderId;

  /// Called with the folder chosen in the move sub-menu, or null for "Home"
  /// (no folder).
  final ValueChanged<String?>? onMoveTo;
  final VoidCallback? onLockSelected;
  final VoidCallback? onDeleteSelected;

  /// Folder page: renames the folder from the title line.
  final VoidCallback? onEditTitle;

  @override
  State<AppFab> createState() => AppFabState();
}

mixin _FabStateMixin on State<AppFab> {
  bool? _isManuallyExpanded;
  bool _wasKeyboardClosed = true;
  FabVerticalMenu _verticalMenu = FabVerticalMenu.none;
  FabVerticalMenu _moveReturnTo = FabVerticalMenu.none;
  List<Note> _availableNotes = [];
  List<Folder> _availableFolders = [];

  // Sorting state for the link and move sub-menu lists.
  ListSortCriteria _sortCriteria = ListSortCriteria.date;
  bool _isAscending = true;

  // Measurement keys for dynamic height calculation
  final GlobalKey _colorMenuKey = GlobalKey();
  final GlobalKey _addMenuKey = GlobalKey();
  final GlobalKey _moreMenuKey = GlobalKey();
  final GlobalKey _linkMenuKey = GlobalKey();
  final GlobalKey _moveMenuKey = GlobalKey();

  double _colorMenuHeight = 0;
  double _addMenuHeight = 0;
  double _moreMenuHeight = 0;
  double _linkMenuHeight = 0;
  double _moveMenuHeight = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditorMode && widget.isAddMode) {
      _isManuallyExpanded = false;
    }
    // Measure heights after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureMenuHeights());
  }

  void _measureMenuHeights() {
    if (!mounted) return;
    setState(() {
      _colorMenuHeight = _colorMenuKey.currentContext?.size?.height ?? 0;
      _addMenuHeight = _addMenuKey.currentContext?.size?.height ?? 0;
      _moreMenuHeight = _moreMenuKey.currentContext?.size?.height ?? 0;
      _linkMenuHeight = _linkMenuKey.currentContext?.size?.height ?? 0;
      _moveMenuHeight = _moveMenuKey.currentContext?.size?.height ?? 0;
    });
  }

  /// Collapses the FAB back to its reduced (circular) form.
  void collapse() {
    if (_isManuallyExpanded != false || _verticalMenu != FabVerticalMenu.none) {
      setState(() {
        _isManuallyExpanded = false;
        _verticalMenu = FabVerticalMenu.none;
      });
    }
  }

  void closeVerticalMenu() {
    if (_verticalMenu != FabVerticalMenu.none) {
      setState(() => _verticalMenu = FabVerticalMenu.none);
    }
  }

  Future<void> _toggleVerticalMenu(FabVerticalMenu menu) async {
    if (menu == FabVerticalMenu.link) {
      final repository = getIt<NotesRepository>();
      final notes = await repository.loadNotes();
      setState(() {
        _availableNotes = notes
            .where((n) => n.id != widget.currentNoteId && !n.isDeleted)
            .toList();
      });
    }

    setState(() {
      _verticalMenu = (_verticalMenu == menu) ? FabVerticalMenu.none : menu;
      if (_verticalMenu != FabVerticalMenu.none) {
        _isManuallyExpanded = true;
      }
    });
    // Re-measure after state change to ensure accuracy
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureMenuHeights());
  }

  /// Opens the "move to folder" sub-menu. [returnTo] is the menu the back
  /// action goes back to (the more menu, or none from the selection bar).
  Future<void> _openMoveMenu(FabVerticalMenu returnTo) async {
    final NotesRepository repository = getIt<NotesRepository>();
    final List<Folder> folders = repository is FoldersRepository
        ? await (repository as FoldersRepository).loadFolders()
        : const <Folder>[];
    if (!mounted) return;
    setState(() {
      _availableFolders = folders
          .where((Folder folder) => folder.id != widget.currentFolderId)
          .toList();
      _moveReturnTo = returnTo;
      _verticalMenu = FabVerticalMenu.move;
      _isManuallyExpanded = true;
    });
    // Re-measure after state change to ensure accuracy
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureMenuHeights());
  }
}

class AppFabState extends State<AppFab>
    with _FabStateMixin, _FabBarsMixin, _FabMenusMixin {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double btnHeight = 64.0;
    const double borderRadiusValue = 55.0;

    final bool isKeyboardClosed = MediaQuery.of(context).viewInsets.bottom == 0;
    final bool isMenuOpen = _verticalMenu != FabVerticalMenu.none;

    if (isKeyboardClosed != _wasKeyboardClosed) {
      _isManuallyExpanded = null;
      _wasKeyboardClosed = isKeyboardClosed;
    }

    final bool isBarMode =
        widget.isSearchMode || widget.isSelectionMode || widget.isFindMode;
    bool isExpanded = isBarMode;
    if (!isBarMode) {
      // Home and editor/folder share the circular <-> extended model.
      if (widget.isEditorMode) {
        isExpanded = _isManuallyExpanded ??
            (isKeyboardClosed && !widget.collapsedByDefault);
      } else {
        // Home: the "+" is the rest form; it expands on tap.
        isExpanded = _isManuallyExpanded ?? false;
      }
    }
    // While the folder title is being renamed, the FAB stays reduced
    // (circular) whatever the keyboard/menu state.
    if (widget.isTitleEditing) {
      isExpanded = false;
    }

    if (!isExpanded && isMenuOpen) {
      _verticalMenu = FabVerticalMenu.none;
    }

    // Target width based on state
    final double targetExpandedWidth = isMenuOpen || !isKeyboardClosed
        ? screenWidth - 24.0
        : screenWidth - 48.0;

    double currentWidth = btnHeight;
    if (isExpanded || isMenuOpen) {
      currentWidth = targetExpandedWidth;
    }

    // Translation calculation.
    double tx = 0.0;
    if ((isExpanded || isMenuOpen) && (isMenuOpen || !isKeyboardClosed)) {
      tx = 12.0;
    }

    double ty = 0.0;
    if (isMenuOpen) {
      ty = 8.0;
    } else if (!isKeyboardClosed) {
      ty = 12.0;
    }

    // Dynamic Vertical Menu Heights
    double verticalMenuHeight = 0;
    if (_verticalMenu == FabVerticalMenu.color) {
      verticalMenuHeight = _colorMenuHeight > 0 ? _colorMenuHeight : 250.0;
    } else if (_verticalMenu == FabVerticalMenu.add) {
      verticalMenuHeight = _addMenuHeight > 0 ? _addMenuHeight : 190.0;
    } else if (_verticalMenu == FabVerticalMenu.more) {
      verticalMenuHeight = _moreMenuHeight > 0 ? _moreMenuHeight : 310.0;
    } else if (_verticalMenu == FabVerticalMenu.link) {
      final double maxMenuHeight = screenHeight * (2 / 3);
      verticalMenuHeight = _linkMenuHeight > 0 ? _linkMenuHeight : 300.0;
      if (verticalMenuHeight > maxMenuHeight) {
        verticalMenuHeight = maxMenuHeight;
      }
    } else if (_verticalMenu == FabVerticalMenu.move) {
      final double maxMenuHeight = screenHeight * (2 / 3);
      verticalMenuHeight = _moveMenuHeight > 0 ? _moveMenuHeight : 300.0;
      if (verticalMenuHeight > maxMenuHeight) {
        verticalMenuHeight = maxMenuHeight;
      }
    }

    // In search mode the bar is more compact (48) than the default (64),
    // and only when the keyboard is open (the "high" position).
    final double barHeight =
        ((widget.isSearchMode || widget.isFindMode) && !isKeyboardClosed)
        ? 48.0
        : btnHeight;

    double currentHeight = barHeight;
    if (isMenuOpen) {
      currentHeight += verticalMenuHeight;
    }

    return TapRegion(
      // The theme toggle shares this group, so tapping it keeps the menu open.
      groupId: fabTapGroup,
      // Tapping anywhere else closes the menu, then folds the FAB back to its
      // resting form (circular when the page has a reduce action).
      onTapOutside: (_) => collapse(),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: currentHeight,
      width: currentWidth,
      clipBehavior: Clip.antiAlias,
      transform: Matrix4.translationValues(tx, ty, 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: isMenuOpen
          ? BorderRadius.vertical(
              top: const Radius.circular(24.0),
              bottom: Radius.circular(borderRadiusValue),
            )
          : BorderRadius.circular(borderRadiusValue),
        // Light rule in dark, dark rule in light; width 1.0 in both themes.
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double expansionProgress = isExpanded || isMenuOpen
              ? (constraints.maxWidth - btnHeight) /
                    (targetExpandedWidth - btnHeight)
              : 0.0;

          final bool showContent =
              !isExpanded || isMenuOpen || expansionProgress > 0.8;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Measurement zone - Unconstrained height to avoid race conditions during animation
              Offstage(
                child: OverflowBox(
                  // Measure at a fixed open-menu width so the heights stay
                  // stable no matter the current FAB width (the closed FAB is
                  // only 64px wide and would otherwise under-measure).
                  minWidth: 0,
                  maxWidth: screenWidth - 24.0,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: _colorMenuKey,
                        child: _buildColorMenu(context),
                      ),
                      Container(
                        key: _addMenuKey,
                        child: _buildAddMenu(context),
                      ),
                      Container(
                        key: _moreMenuKey,
                        child: _buildMoreMenu(context),
                      ),
                      Container(
                        key: _linkMenuKey,
                        child: _buildLinkMenu(context, isMeasurement: true),
                      ),
                      Container(
                        key: _moveMenuKey,
                        child: _buildMoveMenu(context, isMeasurement: true),
                      ),
                    ],
                  ),
                ),
              ),

              if (isMenuOpen)
                Positioned(
                  bottom: btnHeight,
                  left: 0,
                  right: 0,
                  top: 0,
                  child: AnimatedOpacity(
                    opacity: showContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _buildVerticalMenuContent(
                      context,
                      targetExpandedWidth,
                      verticalMenuHeight,
                    ),
                  ),
                ),

              SizedBox(
                height: barHeight,
                child: AnimatedOpacity(
                  opacity: showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  // Only the icons swap: the FAB box itself does not move.
                  // The outgoing set zooms out while the incoming zooms in.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.75,
                                end: 1.0,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: KeyedSubtree(
                      key: ValueKey<bool>(widget.isSelectionMode),
                      child: _buildMainContent(
                        context,
                        isExpanded,
                        targetExpandedWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
