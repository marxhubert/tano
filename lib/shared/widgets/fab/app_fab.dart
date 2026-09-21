import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

// Primary button tokens from site/site.css (.btn), drawn a touch translucent
// over a blur so the page shows through, like the site bar. Shared across every
// FAB mode.
const double _fabLabelSize = 14.72;
const double _fabSurfaceAlpha = .86;
Color _fabForeground(BuildContext context) =>
    Theme.of(context).colorScheme.onPrimary;
Color _fabMenuSurface(BuildContext context) =>
    Theme.of(context).colorScheme.primary.withValues(alpha: _fabSurfaceAlpha);

/// The open action's zone paints the menu's own surface, so the zone and the
/// panel read as one piece of teal: the shape marks the active action, not a
/// tint. A lighter tint here is what left the two teals in the first place.
Color _fabActiveSurface(BuildContext context) => _fabMenuSurface(context);
Color _fabImportant(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF603600)
    : const Color(0xFFFFE0B2);
Color _fabDestructive(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF8C1D18)
    : const Color(0xFFFFDAD6);

/// The unified FAB that morphs between various states (Home, Search, Selection, Editor).
class AppFab extends StatefulWidget {
  const AppFab({
    super.key,
    this.isSearchMode = false,
    this.isSelectionMode = false,
    this.canMove = true,
    this.canLock = true,
    this.canDelete = true,
    this.isEditorMode = false,
    this.isTaskMode = false,
    this.onDescriptionSelected,
    this.onLayoutChanged,
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
    this.onAddTask,
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
  final bool canLock;

  /// Selection mode: whether the "delete" action is available. It is refused
  /// when nothing is selected.
  final bool canDelete;
  final bool isEditorMode;
  final bool isTaskMode;
  final VoidCallback? onDescriptionSelected;
  final VoidCallback? onLayoutChanged;

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
  final VoidCallback? onAddTask;
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

  /// Whether those lists have been read at least once: before that, nothing is
  /// refused, so a menu never opens greyed out by surprise.
  bool _notesLoaded = false;
  bool _foldersLoaded = false;

  /// Whether the app holds a folder at all. The move menu filters the note's
  /// own folder out, but a note sitting in the only folder can still go home.
  bool _hasFolders = false;

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

  void _expand() {
    setState(() => _isManuallyExpanded = true);
  }

  void closeVerticalMenu() {
    if (_verticalMenu != FabVerticalMenu.none) {
      setState(() => _verticalMenu = FabVerticalMenu.none);
    }
  }

  /// Reads the notes the "link a note" list can offer: every note but this one.
  Future<void> _loadNotes() async {
    if (!getIt.isRegistered<NotesRepository>()) return;
    final List<Note> notes = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _availableNotes = notes
          .where(
            (n) =>
                n.id != widget.currentNoteId &&
                !n.isDeleted &&
                (!widget.isTaskMode || !n.isTask),
          )
          .toList();
      _notesLoaded = true;
    });
  }

  /// Reads what the "move to" list can offer: every folder but the one the note
  /// already sits in, and whether there is any folder at all.
  Future<void> _loadFolders() async {
    if (!getIt.isRegistered<NotesRepository>()) return;
    final NotesRepository repository = getIt<NotesRepository>();
    final List<Folder> folders = repository is FoldersRepository
        ? await (repository as FoldersRepository).loadFolders()
        : const <Folder>[];
    if (!mounted) return;
    setState(() {
      _hasFolders = folders.isNotEmpty;
      _availableFolders = folders
          .where((Folder folder) => folder.id != widget.currentFolderId)
          .toList();
      _foldersLoaded = true;
    });
  }

  Future<void> _toggleVerticalMenu(FabVerticalMenu menu) async {
    // The link and move sub-menus are built from those lists, and the item that
    // opens them has to know whether they are empty: read them first.
    if (menu == FabVerticalMenu.link || menu == FabVerticalMenu.add) {
      await _loadNotes();
    } else if (menu == FabVerticalMenu.more) {
      await _loadFolders();
    }
    if (!mounted) return;

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
    await _loadFolders();
    if (!mounted) return;
    setState(() {
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
  (bool, double, double)? _lastReportedLayout;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final MediaQueryData media = MediaQuery.of(context);
    // The FAB slot loses the side padding; subtract it so the expanded bar stops
    // at the safe area and only grows leftwards.
    final double safeSide = media.padding.left > media.padding.right
        ? media.padding.left
        : media.padding.right;
    final double screenWidth = media.size.width - safeSide * 2;
    // The FAB follows the content column, not the raw window: on a tablet it
    // keeps the width of the centred page.
    final double contentWidth = screenWidth < appContentMaxWidth
        ? screenWidth
        : appContentMaxWidth;
    const double btnHeight = 64.0;

    final bool isKeyboardClosed = MediaQuery.of(context).viewInsets.bottom == 0;
    final bool isMenuOpen = _verticalMenu != FabVerticalMenu.none;

    final fabRadius = isMenuOpen
        ? const BorderRadius.vertical(
            top: Radius.circular(24),
            bottom: Radius.circular(55),
          )
        : BorderRadius.circular(55);
    final buttonColor = _fabMenuSurface(context);
    final buttonBorder = Color.lerp(
      Theme.of(context).colorScheme.primary,
      Colors.black,
      .22,
    )!;

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
        isExpanded =
            _isManuallyExpanded ??
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

    // Target width based on state. The right edge is the anchor; the resting bar
    // keeps the same 24 from the column on its left too, so both gaps to the
    // cards read the same (12 each). An open menu or a keyboard takes the wider
    // form.
    final double targetExpandedWidth = isMenuOpen || !isKeyboardClosed
        ? contentWidth - 24.0
        : contentWidth - 48.0;

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

    // Size menus to the viewport above the keyboard, preserving the app bar
    // and safe areas. Long menus scroll inside this bounded surface.
    final availableMenuHeight = math.max(
      0.0,
      screenHeight -
          media.viewInsets.bottom -
          media.viewPadding.top -
          media.viewPadding.bottom -
          kToolbarHeight -
          24.0 -
          barHeight,
    );
    verticalMenuHeight = math.min(verticalMenuHeight, availableMenuHeight);

    double currentHeight = barHeight;
    if (isMenuOpen) {
      currentHeight += verticalMenuHeight;
    }

    final layout = (
      isExpanded,
      currentHeight,
      MediaQuery.viewInsetsOf(context).bottom,
    );
    if (_lastReportedLayout != layout) {
      _lastReportedLayout = layout;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLayoutChanged?.call();
      });
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _hoverEffect(
        TapRegion(
          // The theme toggle shares this group, so tapping it keeps the menu open.
          groupId: fabTapGroup,
          // Tapping anywhere else closes the menu, then folds the FAB back to its
          // resting form (circular when the page has a reduce action).
          onTapOutside: (_) => collapse(),
          child: AnimatedContainer(
            onEnd: widget.onLayoutChanged,
            duration: TanoMotion.base,
            curve: Curves.easeInOut,
            height: currentHeight,
            width: currentWidth,
            clipBehavior: Clip.antiAlias,
            transform: Matrix4.translationValues(tx, ty, 0.0),
            decoration: BoxDecoration(
              color: buttonColor,
              border: Border.all(color: buttonBorder),
              borderRadius: fabRadius,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, .9),
                  offset: Offset(0, 10),
                  blurRadius: 18,
                  spreadRadius: -14,
                ),
              ],
            ),
            foregroundDecoration: _PrimaryButtonEdge(buttonBorder, fabRadius),
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
                    // The masthead blur: whatever shows through the paper is
                    // softened, exactly like the site bar.
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // Measurement zone - Unconstrained height to avoid race conditions during animation
                    Offstage(
                      child: OverflowBox(
                        // Measure at a fixed open-menu width so the heights stay
                        // stable no matter the current FAB width (the closed FAB is
                        // only 64px wide and would otherwise under-measure).
                        minWidth: 0,
                        maxWidth: contentWidth - 24.0,
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
                              child: _buildLinkMenu(
                                context,
                                isMeasurement: true,
                              ),
                            ),
                            Container(
                              key: _moveMenuKey,
                              child: _buildMoveMenu(
                                context,
                                isMeasurement: true,
                              ),
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
                          duration: TanoMotion.fast,
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
                        duration: TanoMotion.fast,
                        // Only the icons swap: the FAB box itself does not move.
                        // The outgoing set zooms out while the incoming zooms in.
                        child: AnimatedSwitcher(
                          duration: TanoMotion.base,
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
        ),
      ),
    );
  }

  Widget _hoverEffect(Widget child) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: _hovered ? 1 : 0),
    duration: const Duration(milliseconds: 160),
    curve: Curves.ease,
    child: child,
    builder: (context, hover, child) {
      final brightness = 1 + .05 * hover;
      return Transform.translate(
        offset: Offset(0, -hover),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix([
            brightness,
            0,
            0,
            0,
            0,
            0,
            brightness,
            0,
            0,
            0,
            0,
            0,
            brightness,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        ),
      );
    },
  );
}

/// The site's 1px inset white highlight, painted above menu backgrounds, then
/// its opaque 1px border. The offset path reproduces CSS inset 0 1px 0.
class _PrimaryButtonEdge extends Decoration {
  const _PrimaryButtonEdge(this.border, this.radius);
  final Color border;
  final BorderRadius radius;
  @override
  Decoration? lerpFrom(Decoration? a, double t) => a is _PrimaryButtonEdge
      ? _PrimaryButtonEdge(
          Color.lerp(a.border, border, t)!,
          BorderRadius.lerp(a.radius, radius, t)!,
        )
      : super.lerpFrom(a, t);
  @override
  Decoration? lerpTo(Decoration? b, double t) => b is _PrimaryButtonEdge
      ? _PrimaryButtonEdge(
          Color.lerp(border, b.border, t)!,
          BorderRadius.lerp(radius, b.radius, t)!,
        )
      : super.lerpTo(b, t);
  @override
  bool operator ==(Object other) =>
      other is _PrimaryButtonEdge &&
      other.border == border &&
      other.radius == radius;
  @override
  int get hashCode => Object.hash(border, radius);
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _PrimaryButtonEdgePainter(border, radius);
}

class _PrimaryButtonEdgePainter extends BoxPainter {
  _PrimaryButtonEdgePainter(this.border, this.radius);
  final Color border;
  final BorderRadius radius;
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final outer = radius.toRRect(rect).scaleRadii();
    final inside = outer.deflate(1);
    final highlight = Path.combine(
      PathOperation.difference,
      Path()..addRRect(inside),
      Path()..addRRect(inside.shift(const Offset(0, 1))),
    );
    canvas.drawPath(
      highlight,
      Paint()..color = const Color.fromRGBO(255, 255, 255, .25),
    );
    canvas.drawRRect(
      outer.deflate(.5),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
