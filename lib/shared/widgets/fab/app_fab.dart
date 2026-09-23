import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'fab_geometry.dart';
import 'fab_state.dart';

export 'fab_state.dart' show FabVerticalMenu;
import 'package:tano/shared/widgets/theme.dart';

part 'fab_bars.dart';
part 'fab_items.dart';
part 'fab_menus.dart';
part 'fab_lifecycle.dart';
part 'fab_measurement.dart';

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
Color _fabActiveSurface(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
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
    this.onLeft = false,
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

  /// When true the FAB sits on the left: an expanded bar grows rightwards and
  /// its reduce chevron moves to the head. A definitive choice, in portrait too.
  final bool onLeft;

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

class AppFabState extends State<AppFab>
    with _FabStateMixin, _FabBarsMixin, _FabMenusMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isExpanded = _presentation.expanded;
    final isMenuOpen = _verticalMenu != FabVerticalMenu.none;
    final geometry = FabGeometry.resolve(
      media: media,
      expanded: isExpanded,
      menuOpen: isMenuOpen,
      compactBar: _mode == FabMode.search || _mode == FabMode.find,
      onLeft: widget.onLeft,
      menuHeight: _measuredMenuHeight,
    );
    final targetExpandedWidth = geometry.expandedWidth;
    final barHeight = geometry.barHeight;
    final fabRadius = geometry.radius;
    final buttonColor = _fabMenuSurface(context);
    final buttonBorder = Color.lerp(
      Theme.of(context).colorScheme.primary,
      Colors.black,
      .22,
    )!;
    return _FabSizeObserver(
      onSizeChanged: (_) => _scheduleLayoutReport(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: _hoverEffect(
          TapRegion(
            // The theme toggle shares this group, so tapping it keeps the menu open.
            groupId: fabTapGroup,
            // Tapping anywhere else closes the menu, then folds the FAB back to its
            // resting form (circular when the page has a reduce action).
            onTapOutside: (_) => collapse(),
            child: TextFieldTapRegion(
              child: AnimatedContainer(
                onEnd: _reportSettledLayout,
                duration: TanoMotion.base,
                curve: Curves.easeInOut,
                height: geometry.height,
                width: geometry.width,
                clipBehavior: Clip.antiAlias,
                // Null while resting: a fresh identity Matrix4 each build made the
                // implicit animation interpolate for nothing.
                transform: (geometry.offset == Offset.zero)
                    ? null
                    : Matrix4.translationValues(
                        geometry.offset.dx,
                        geometry.offset.dy,
                        0.0,
                      ),
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
                foregroundDecoration: _PrimaryButtonEdge(
                  buttonBorder,
                  fabRadius,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final expansionRange = targetExpandedWidth - 64;
                    final expansionProgress = expansionRange > 0
                        ? ((constraints.maxWidth - 64) / expansionRange).clamp(
                            0.0,
                            1.0,
                          )
                        : 1.0;
                    final showContent =
                        !isExpanded || isMenuOpen || expansionProgress > .8;

                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // The masthead blur: whatever shows through the paper is
                        // softened, exactly like the site bar.
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        if (isMenuOpen)
                          Positioned(
                            bottom: barHeight,
                            left: 0,
                            right: 0,
                            height: geometry.menuHeight,
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                              minWidth: targetExpandedWidth,
                              maxWidth: targetExpandedWidth,
                              minHeight: 0,
                              maxHeight: geometry.maxMenuHeight,
                              child: _FabSizeObserver(
                                key: ValueKey(_verticalMenu),
                                onSizeChanged: _menuMeasured,
                                child: _buildVerticalMenuContent(context),
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
                            child:
                                (_mode == FabMode.search ||
                                    _mode == FabMode.find)
                                ? _buildMainContent(
                                    context,
                                    isExpanded,
                                    targetExpandedWidth,
                                  )
                                : AnimatedSwitcher(
                                    duration: TanoMotion.base,
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: .75,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: KeyedSubtree(
                                      key: ValueKey(_mode),
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
