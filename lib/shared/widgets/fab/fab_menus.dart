part of 'app_fab.dart';

mixin _FabMenusMixin on _FabStateMixin {
  Widget _buildVerticalMenuContent(
    BuildContext context,
    double width,
    double height,
  ) {
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
      case FabVerticalMenu.move:
        content = _buildMoveMenu(context);
        break;
      default:
        content = const SizedBox.shrink();
    }

    // The dark surface fills the whole menu area while the content stays
    // anchored at the bottom. The content is laid out at its final size even
    // while the FAB animates: the animating container clips it, so it never
    // wraps or squashes into a half-grown menu area.
    return Container(
      decoration: BoxDecoration(color: _fabMenuSurface(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          alignment: Alignment.bottomCenter,
          child: content,
        ),
      ),
    );
  }

  List<Note> _getSortedNotes() {
    final List<Note> sorted = List.from(_availableNotes);

    sorted.sort((a, b) {
      int cmp;
      if (_sortCriteria == ListSortCriteria.date) {
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
          icon: Symbols.sticky_note_2,
          iconSize: 20.0,
          fontSize: 17.0,
          maxLines: 2,
          label: note.title.isEmpty ? AppText.tr('no_title') : note.title,
          onTap: () {
            widget.onNoteLinkSelected?.call(note);
            setState(() => _verticalMenu = FabVerticalMenu.none);
          },
        );
      }),
    );

    return _SubMenuLayout(
      title: AppText.tr('back'),
      onBack: () => setState(() => _verticalMenu = FabVerticalMenu.add),
      actions: _buildSortActions(),
      isMeasurement: isMeasurement,
      child: content,
    );
  }

  List<Folder> _getSortedFolders() {
    final List<Folder> sorted = List.from(_availableFolders);
    sorted.sort((a, b) {
      int cmp;
      if (_sortCriteria == ListSortCriteria.date) {
        cmp = b.date.compareTo(a.date);
      } else {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _isAscending ? cmp : -cmp;
    });
    return sorted;
  }

  /// The folder list offered by the "move to" action. It mirrors the note-link
  /// list, header included, so both second-degree menus feel the same.
  Widget _buildMoveMenu(BuildContext context, {bool isMeasurement = false}) {
    final List<Folder> folders = _getSortedFolders();

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _VerticalMenuItem(
          icon: Symbols.home,
          iconSize: 20.0,
          fontSize: 17.0,
          maxLines: 2,
          label: AppText.tr('no_folder'),
          onTap: () {
            widget.onMoveTo?.call(null);
            setState(() => _verticalMenu = FabVerticalMenu.none);
          },
        ),
        for (final Folder folder in folders)
          _VerticalMenuItem(
            icon: Symbols.folder,
            iconSize: 20.0,
            fontSize: 17.0,
            maxLines: 2,
            label: folder.name,
            onTap: () {
              widget.onMoveTo?.call(folder.id);
              setState(() => _verticalMenu = FabVerticalMenu.none);
            },
          ),
      ],
    );

    return _SubMenuLayout(
      title: AppText.tr('back'),
      onBack: () => setState(() => _verticalMenu = _moveReturnTo),
      actions: _buildSortActions(),
      isMeasurement: isMeasurement,
      child: content,
    );
  }

  /// The two sort switches shared by the link and move sub-menu headers.
  List<Widget> _buildSortActions() {
    return <Widget>[
      IconButton(
        tooltip: AppText.tr('sort_by'),
        icon: Icon(
          _sortCriteria == ListSortCriteria.date
              ? Symbols.history_2
              : Symbols.sort_by_alpha,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => setState(() {
          _sortCriteria = _sortCriteria == ListSortCriteria.date
              ? ListSortCriteria.title
              : ListSortCriteria.date;
        }),
        padding: const EdgeInsets.all(8.0),
        constraints: const BoxConstraints(),
      ),
      IconButton(
        tooltip: AppText.tr('sort_direction'),
        icon: Icon(
          _isAscending ? Symbols.arrow_downward : Symbols.arrow_upward,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => setState(() => _isAscending = !_isAscending),
        padding: const EdgeInsets.all(8.0),
        constraints: const BoxConstraints(),
      ),
    ];
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
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // The couplet keeps its height; it becomes a circle. Five fit per
              // row, and the selected one gets a soft halo 25% larger.
              const double spacing = 16.0;
              final double currentWidth =
                  (constraints.maxWidth - spacing * 3.0) / 4.0;
              final double diameter = currentWidth / 1.8;
              final double halo = diameter * 1.36;
              return GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  mainAxisExtent: diameter,
                ),
                itemCount: TanoPastels.all.length,
                itemBuilder: (context, index) {
                  final pair = TanoPastels.all[index];
                  final bool isSelected =
                      pair.name == (widget.currentCategory ?? 'nuage');

                  return GestureDetector(
                    onTap: () => widget.onColorSelected?.call(pair.name),
                    child: Center(
                      child: OverflowBox(
                        maxWidth: halo,
                        maxHeight: halo,
                        child: SizedBox(
                          width: halo,
                          height: halo,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              // Very soft white disc behind the selected couplet.
                              if (isSelected)
                                Container(
                                  width: halo,
                                  height: halo,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Container(
                                width: diameter,
                                height: diameter,
                                clipBehavior: Clip.antiAlias,
                                // The border must sit above the two colours:
                                // under the clipped content it only left a
                                // fuzzy, partial edge.
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                foregroundDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white30,
                                    width: 1.0,
                                  ),
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    // Rotated 45°: the split becomes diagonal.
                                    Transform.rotate(
                                      angle: math.pi / 4,
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Container(color: pair.light),
                                          ),
                                          Expanded(
                                            child: Container(color: pair.dark),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: <Widget>[
                                            // White disc behind the check.
                                            Container(
                                              width: diameter * 0.40,
                                              height: diameter * 0.40,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            // Full amber disc...
                                            Icon(
                                              Symbols.check_circle,
                                              color: tanoAmber,
                                              fill: 1.0,
                                              size: diameter * 0.53,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    // On the folder page the "+" offers a cover image or a new note.
    if (widget.isFolderMode) {
      return _buildVerticalList([
        _VerticalMenuItem(
          icon: Symbols.imagesmode,
          label: AppText.tr('option_image'),
          onTap: widget.onImageSelected,
        ),
        _VerticalMenuItem(
          icon: Symbols.add_notes,
          label: AppText.tr('add_note'),
          onTap: () {
            _toggleVerticalMenu(FabVerticalMenu.add);
            widget.onAddNote?.call();
          },
        ),
      ]);
    }
    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Symbols.image,
        label: AppText.tr('option_image'),
        onTap: widget.onImageSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.checklist,
        label: AppText.tr('option_checklist'),
        onTap: widget.onChecklistSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.sticky_note_2,
        label: AppText.tr('option_link'),
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.link);
          widget.onLinkSelected?.call();
        },
      ),
      _VerticalMenuItem(
        icon: Symbols.attachment,
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

    // On the folder page only the folder-relevant actions are offered.
    if (widget.isFolderMode) {
      return _buildVerticalList([
        _VerticalMenuItem(
          icon: Symbols.label_important,
          fill: widget.isImportant ? 1.0 : 0.0,
          label: AppText.tr('important'),
          iconColor: widget.isImportant ? tanoAmber : null,
          onTap: widget.onImportantSelected,
        ),
        _VerticalMenuItem(
          icon: Symbols.edit_square,
          label: AppText.tr('edit'),
          onTap: widget.onEditTitle,
        ),
        _VerticalMenuItem(
          icon: widget.isLocked ? Symbols.lock_open : Symbols.lock,
          label: widget.isLocked
              ? AppText.tr('option_unlock')
              : AppText.tr('option_lock'),
          onTap: widget.onLockSelected,
        ),
        _VerticalMenuItem(
          icon: Symbols.delete,
          label: capitalizedDelete,
          iconColor: const Color(0xFFFF8A80),
          textColor: const Color(0xFFFF8A80),
          onTap: widget.onDeleteSelected,
        ),
      ]);
    }

    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Symbols.label_important,
        fill: widget.isImportant ? 1.0 : 0.0,
        label: AppText.tr('important'),
        iconColor: widget.isImportant ? tanoAmber : null,
        onTap: widget.onImportantSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.search,
        label: AppText.tr('option_find'),
        onTap: widget.onFindSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.drive_file_move,
        label: AppText.tr('option_move'),
        onTap: () => _openMoveMenu(FabVerticalMenu.more),
      ),
      _VerticalMenuItem(
        icon: widget.isLocked ? Symbols.lock_open : Symbols.lock,
        label: widget.isLocked ? AppText.tr('option_unlock') : AppText.tr('option_lock'),
        onTap: widget.onLockSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.delete,
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
}
