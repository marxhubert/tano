import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

enum FabVerticalMenu { none, add, color, more, link }

enum LinkSortCriteria { date, title }

/// The unified FAB that morphs between various states (Home, Search, Selection, Editor).
class AppFab extends StatefulWidget {
  const AppFab({
    super.key,
    this.isSearchMode = false,
    this.isSelectionMode = false,
    this.isEditorMode = false,
    this.isAddMode = false,
    this.isPinned = false,
    this.isImportant = false,
    this.controller,
    this.focusNode,
    this.onAdd,
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
    this.onImageSelected,
    this.onChecklistSelected,
    this.onLinkSelected,
    this.onNoteLinkSelected,
    this.onAttachmentSelected,
    this.onPinSelected,
    this.onImportantSelected,
    this.onFindSelected,
    this.onMoveSelected,
    this.onLockSelected,
    this.onDeleteSelected,
    this.onCollaboratorsSelected,
    this.onShareSelected,
  });

  final bool isSearchMode;
  final bool isSelectionMode;
  final bool isEditorMode;
  final bool isAddMode;
  final bool isPinned;
  final bool isImportant;
  final String? currentNoteId;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onAdd;
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
  final VoidCallback? onPinSelected;
  final VoidCallback? onImportantSelected;
  final VoidCallback? onFindSelected;
  final VoidCallback? onMoveSelected;
  final VoidCallback? onLockSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onCollaboratorsSelected;
  final VoidCallback? onShareSelected;

  @override
  State<AppFab> createState() => AppFabState();
}

class AppFabState extends State<AppFab> {
  bool? _isManuallyExpanded;
  bool _wasKeyboardClosed = true;
  FabVerticalMenu _verticalMenu = FabVerticalMenu.none;
  List<Note> _availableNotes = [];
  
  // Sorting state for links
  LinkSortCriteria _sortCriteria = LinkSortCriteria.date;
  bool _isAscending = true;

  // Measurement keys for dynamic height calculation
  final GlobalKey _colorMenuKey = GlobalKey();
  final GlobalKey _addMenuKey = GlobalKey();
  final GlobalKey _moreMenuKey = GlobalKey();
  final GlobalKey _linkMenuKey = GlobalKey();

  double _colorMenuHeight = 0;
  double _addMenuHeight = 0;
  double _moreMenuHeight = 0;
  double _linkMenuHeight = 0;

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
    });
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

    bool isExpanded = widget.isSearchMode || widget.isSelectionMode;
    if (widget.isEditorMode) {
      isExpanded = _isManuallyExpanded ?? isKeyboardClosed;
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

    // Translation calculation
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
    }

    // In search mode the bar is more compact (48) than the default (64),
    // and only when the keyboard is open (the "high" position).
    final double barHeight =
        (widget.isSearchMode && !isKeyboardClosed) ? 48.0 : btnHeight;

    double currentHeight = barHeight;
    if (isMenuOpen) {
      currentHeight += verticalMenuHeight;
    }

    return AnimatedContainer(
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
              top: Radius.circular(24.0), 
              bottom: Radius.circular(borderRadiusValue))
          : BorderRadius.circular(borderRadiusValue),
        border: Border.all(
          color: getBorderColor(
            Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final double expansionProgress = isExpanded || isMenuOpen
            ? (constraints.maxWidth - btnHeight) /
                (targetExpandedWidth - btnHeight)
            : 0.0;
        
        final bool showContent = !isExpanded || isMenuOpen || expansionProgress > 0.8;

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
                    Container(key: _colorMenuKey, child: _buildColorMenu(context)),
                    Container(key: _addMenuKey, child: _buildAddMenu(context)),
                    Container(key: _moreMenuKey, child: _buildMoreMenu(context)),
                    Container(key: _linkMenuKey, child: _buildLinkMenu(context, isMeasurement: true)),
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
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildVerticalMenuContent(context),
                  ),
                ),
              ),
            
            SizedBox(
              height: barHeight,
              child: AnimatedOpacity(
                opacity: showContent ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: _buildMainContent(context, isExpanded, targetExpandedWidth),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVerticalMenuContent(BuildContext context) {
    Widget content;
    switch (_verticalMenu) {
      case FabVerticalMenu.color:
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _buildColorMenu(context),
        );
        break;
      case FabVerticalMenu.add:
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _buildAddMenu(context),
        );
        break;
      case FabVerticalMenu.more:
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _buildMoreMenu(context),
        );
        break;
      case FabVerticalMenu.link:
        content = _buildLinkMenu(context);
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
      ),
      child: content,
    );
  }

  List<Note> _getSortedNotes() {
    final List<Note> sorted = List.from(_availableNotes);
    
    sorted.sort((a, b) {
      int cmp;
      if (_sortCriteria == LinkSortCriteria.date) {
        // Date sort: Default Ascending = Newest first
        cmp = b.date.compareTo(a.date);
      } else {
        // Title sort: Default Ascending = A-Z
        cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _isAscending ? cmp : -cmp;
    });
    
    return sorted;
  }

  Widget _buildLinkMenu(BuildContext context, {bool isMeasurement = false}) {
    final sortedNotes = _getSortedNotes();
    
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(sortedNotes.length, (index) {
        final note = sortedNotes[index];
        return _VerticalMenuItem(
          icon: Icons.sticky_note_2,
          iconSize: 18.0,
          fontSize: 13.0,
          maxLines: 2,
          label: note.title.isEmpty ? AppText.tr('no_title') : note.title,
          onTap: () {
            widget.onNoteLinkSelected?.call(note);
            setState(() => _verticalMenu = FabVerticalMenu.none);
          },
        );
      }),
    );

    if (isMeasurement) {
      // Simplified layout for stable measurement
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 36), // Fixed header approximate height
          content,
        ],
      );
    }

    return _SubMenuLayout(
      title: AppText.tr('back'),
      onBack: () => setState(() => _verticalMenu = FabVerticalMenu.add),
      actions: [
        IconButton(
          icon: Icon(
            _sortCriteria == LinkSortCriteria.date ? Icons.sort : Icons.sort_by_alpha,
            size: 20,
            color: Colors.white70,
          ),
          onPressed: () => setState(() {
            _sortCriteria = _sortCriteria == LinkSortCriteria.date 
                ? LinkSortCriteria.title 
                : LinkSortCriteria.date;
          }),
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(),
        ),
        IconButton(
          icon: Icon(
            _isAscending ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up,
            size: 20,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _isAscending = !_isAscending),
          padding: const EdgeInsets.all(8.0),
          constraints: const BoxConstraints(),
        ),
      ],
      child: content,
    );
  }

  Widget _buildColorMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.tr('menu_theme'),
            style: const TextStyle(
                color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1.8,
            ),
            itemCount: TanoPastels.all.length,
            itemBuilder: (context, index) {
              final pair = TanoPastels.all[index];
              final bool isSelected =
                  pair.name == (widget.currentCategory ?? 'nuage');

              return GestureDetector(
                onTap: () => widget.onColorSelected?.call(pair.name),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white30,
                      width: 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Container(color: pair.light)),
                          Expanded(child: Container(color: pair.dark)),
                        ],
                      ),
                      if (isSelected)
                        const Center(
                          child: Icon(Icons.check_circle,
                              color: tanoAmber, size: 20.0),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Icons.crop_original,
        label: AppText.tr('option_image'),
        onTap: widget.onImageSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.checklist,
        label: AppText.tr('option_checklist'),
        onTap: widget.onChecklistSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.sticky_note_2,
        label: AppText.tr('option_link'),
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.link);
          widget.onLinkSelected?.call();
        },
      ),
      _VerticalMenuItem(
        icon: Icons.attachment,
        label: AppText.tr('option_attachment'),
        onTap: widget.onAttachmentSelected,
      ),
    ]);
  }

  Widget _buildMoreMenu(BuildContext context) {
    final String deleteLabel = AppText.tr('delete');
    final String capitalizedDelete = deleteLabel.isNotEmpty
        ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
        : '';

    return _buildVerticalList([
      _VerticalMenuItem(
        icon: widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: AppText.tr('option_pin'),
        iconColor: widget.isPinned ? tanoAmber : null,
        onTap: widget.onPinSelected,
      ),
      _VerticalMenuItem(
        icon: widget.isImportant ? Icons.bookmark : Icons.bookmark_border,
        label: AppText.tr('important'),
        iconColor: widget.isImportant ? tanoAmber : null,
        onTap: widget.onImportantSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.search,
        label: AppText.tr('option_find'),
        onTap: widget.onFindSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.drive_file_move_outlined,
        label: AppText.tr('option_move'),
        onTap: widget.onMoveSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.person_add_alt,
        label: AppText.tr('option_collaborators'),
        onTap: widget.onCollaboratorsSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.share,
        label: AppText.tr('option_share'),
        onTap: widget.onShareSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.lock_outline,
        label: AppText.tr('option_lock'),
        onTap: widget.onLockSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.delete_outline,
        label: capitalizedDelete,
        iconColor: const Color(0xFFFF8A80),
        textColor: const Color(0xFFFF8A80),
        onTap: widget.onDeleteSelected,
      ),
    ]);
  }

  Widget _buildVerticalList(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, bool isExpanded, double targetWidth) {
    if (widget.isEditorMode) return _buildEditorBar(context, isExpanded, targetWidth);
    if (widget.isSelectionMode) return _buildSelectionBar(context, targetWidth);
    if (widget.isSearchMode) return _buildSearchBar(context);
    return _buildDefaultAddButton();
  }

  Widget _buildEditorBar(BuildContext context, bool isExpanded, double targetWidth) {
    if (!isExpanded) {
      return IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        onPressed: () => setState(() => _isManuallyExpanded = true),
      );
    }

    return _buildHorizontalBar(targetWidth, [
      _EditorAction(
        icon: Icons.add,
        isActive: _verticalMenu == FabVerticalMenu.add,
        onTap: () {
          // Keep focus so checklist insertion can use the current caret.
          _toggleVerticalMenu(FabVerticalMenu.add);
        },
      ),
      _EditorAction(
        icon: Icons.color_lens_outlined,
        isActive: _verticalMenu == FabVerticalMenu.color,
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.color);
          widget.onColorLens?.call();
        },
      ),
      _EditorAction(
        icon: Icons.more_vert,
        isActive: _verticalMenu == FabVerticalMenu.more,
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.more);
          widget.onMore?.call();
        },
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 20.0, color: Colors.white),
        onPressed: () => setState(() {
          _verticalMenu = FabVerticalMenu.none;
          _isManuallyExpanded = false;
        }),
      ),
    ]);
  }

  Widget _buildSelectionBar(BuildContext context, double targetWidth) {
    final String deleteLabel = AppText.tr('delete');
    final String capitalizedDelete = deleteLabel.isNotEmpty
        ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
        : deleteLabel;

    return _buildHorizontalBar(targetWidth, [
      _SelectionFabButton(
        icon: Icons.delete,
        label: capitalizedDelete,
        color: const Color(0xFFFF8A80),
        onPressed: widget.onDelete ?? () {},
      ),
      _SelectionFabButton(
        icon: Icons.check_box_outline_blank,
        label: AppText.tr('select_none'),
        onPressed: widget.onClearSelection ?? () {},
      ),
      _SelectionFabButton(
        icon: Icons.select_all,
        label: AppText.tr('select_all'),
        onPressed: widget.onSelectAll ?? () {},
      ),
    ]);
  }

  Widget _buildSearchBar(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => widget.focusNode?.unfocus(),
      child: Container(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          spacing: 8.0,
          children: <Widget>[
            const Icon(Icons.search, color: Colors.white, size: 24.0),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
                decoration: InputDecoration(
                  hintText: AppText.tr('search'),
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: widget.onSearchChanged,
              ),
            ),
            if (widget.controller?.text.isNotEmpty ?? false)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  widget.onReset?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAddButton() {
    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: widget.onAdd,
    );
  }

  Widget _buildHorizontalBar(double width, List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }
}

class _SubMenuLayout extends StatelessWidget {
  const _SubMenuLayout({
    required this.title,
    required this.onBack,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed Header
        Container(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.white70),
                label: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
        ),
        // Scrollable Body
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: isActive ? tanoAmber : Colors.white),
      onPressed: onTap,
    );
  }
}

class _VerticalMenuItem extends StatelessWidget {
  const _VerticalMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.iconSize = 20.0,
    this.fontSize = 14.0,
    this.maxLines,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;
  final double fontSize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: maxLines != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: iconSize),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: textColor ?? Colors.white, fontSize: fontSize),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionFabButton extends StatelessWidget {
  const _SelectionFabButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? Colors.white;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 24.0, color: effectiveColor),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                color: effectiveColor,
                fontWeight: FontWeight.bold,  
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
