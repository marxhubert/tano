part of 'app_fab.dart';

mixin _FabMenusMixin on _FabStateMixin {
  Widget _buildVerticalMenuContent(BuildContext context) {
    // A first-degree menu's space wears the active action's colour, exactly as a
    // second-degree one's list does; the second keeps its header untouched.
    Widget active(Widget child) =>
        ColoredBox(color: _fabActiveSurface(context), child: child);
    return switch (_verticalMenu) {
      FabVerticalMenu.color => active(
        SingleChildScrollView(child: _buildColorMenu(context)),
      ),
      FabVerticalMenu.add => active(
        SingleChildScrollView(child: _buildAddMenu(context)),
      ),
      FabVerticalMenu.more => active(
        SingleChildScrollView(child: _buildMoreMenu(context)),
      ),
      FabVerticalMenu.link => _buildLinkMenu(context),
      FabVerticalMenu.move => _buildMoveMenu(context),
      FabVerticalMenu.none => const SizedBox.shrink(),
    };
  }

  Widget _loadStatus({required bool failed, required VoidCallback retry}) {
    if (failed) {
      return _VerticalMenuItem(
        icon: Symbols.refresh,
        label: AppText.tr('retry'),
        onTap: retry,
      ); //
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(color: _fabForeground(context)),
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

  Widget _buildLinkMenu(BuildContext context) {
    final sortedNotes = _getSortedNotes();

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(sortedNotes.length, (index) {
        final note = sortedNotes[index];
        return _VerticalMenuItem(
          icon: Symbols.sticky_note_2,
          iconSize: 20.0,
          fontSize: _fabLabelSize,
          maxLines: 2,
          label: note.title.isEmpty ? AppText.tr('no_title') : note.title,
          onTap: () {
            closeVerticalMenu();
            widget.onNoteLinkSelected?.call(note);
          },
        );
      }),
    );

    return _SubMenuLayout(
      title: AppText.tr('back'),
      onBack: () => _showMenu(FabVerticalMenu.add),
      actions: _buildSortActions(),
      child: (_notesLoading || _notesFailed)
          ? _loadStatus(
              failed: _notesFailed,
              retry: () => unawaited(_loadNotes()),
            )
          : content,
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
  Widget _buildMoveMenu(BuildContext context) {
    final List<Folder> folders = _getSortedFolders();

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _VerticalMenuItem(
          icon: Symbols.home,
          iconSize: 20.0,
          fontSize: _fabLabelSize,
          maxLines: 2,
          label: AppText.tr('no_folder'),
          onTap: () {
            closeVerticalMenu();
            widget.onMoveTo?.call(null);
          },
        ),
        for (final Folder folder in folders)
          _VerticalMenuItem(
            icon: Symbols.folder,
            iconSize: 20.0,
            fontSize: _fabLabelSize,
            maxLines: 2,
            label: folder.name,
            onTap: () {
              closeVerticalMenu();
              widget.onMoveTo?.call(folder.id);
            },
          ),
      ],
    );

    return _SubMenuLayout(
      title: AppText.tr('back'),
      onBack: () => _showMenu(_presentation.moveReturnTo),
      actions: _buildSortActions(),
      child: (_foldersLoading || _foldersFailed)
          ? _loadStatus(
              failed: _foldersFailed,
              retry: () => unawaited(_loadFolders()),
            )
          : content,
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
          color: _fabForeground(context),
        ),
        onPressed: () => setState(() {
          _sortCriteria = _sortCriteria == ListSortCriteria.date
              ? ListSortCriteria.title
              : ListSortCriteria.date;
        }),
        padding: const EdgeInsets.all(appPaddingTight),
        constraints: const BoxConstraints(),
      ),
      IconButton(
        tooltip: AppText.tr('sort_direction'),
        icon: Icon(
          _isAscending ? Symbols.arrow_downward : Symbols.arrow_upward,
          size: 20,
          color: _fabForeground(context),
        ),
        onPressed: () => setState(() => _isAscending = !_isAscending),
        padding: const EdgeInsets.all(appPaddingTight),
        constraints: const BoxConstraints(),
      ),
    ];
  }

  Widget _buildColorMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(sectionGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.tr('menu_theme'),
            style: TextStyle(
              color: _fabForeground(context),
              fontSize: _fabLabelSize,
            ),
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
                                    color: _fabForeground(
                                      context,
                                    ).withValues(alpha: 0.18),
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
                                    color: _fabForeground(
                                      context,
                                    ).withValues(alpha: .3),
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
                                            child: Container(
                                              color: swatchTone(pair.light),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              color: swatchTone(pair.dark),
                                            ),
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
                                              decoration: BoxDecoration(
                                                color: _fabForeground(context),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            // Full amber disc...
                                            Icon(
                                              Symbols.check_circle,
                                              color: _fabImportant(context),
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
    // On the folder page the "+" offers a new note or a task: a folder has no
    // cover to choose.
    if (widget.isFolderMode) {
      return _buildVerticalList([
        _VerticalMenuItem(
          icon: Symbols.add_notes,
          label: AppText.tr('add_note'),
          onTap: () {
            collapse();
            widget.onAddNote?.call();
          },
        ),
        _VerticalMenuItem(
          icon: Symbols.format_list_bulleted_add,
          label: AppText.tr('add_task'),
          onTap: () {
            collapse();
            widget.onAddTask?.call();
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
      if (!widget.isTaskMode)
        _VerticalMenuItem(
          icon: Symbols.checklist,
          label: AppText.tr('option_checklist'),
          onTap: widget.onChecklistSelected,
        ),
      _VerticalMenuItem(
        icon: Symbols.sticky_note_2,
        label: AppText.tr('option_link'),
        // Nothing to link to when this is the only note.
        enabled:
            !_notesLoaded ||
            _notesLoading ||
            _notesFailed ||
            _availableNotes.isNotEmpty,
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.link);
          widget.onLinkSelected?.call();
        },
      ),
      if (widget.isTaskMode)
        _VerticalMenuItem(
          icon: Symbols.notes,
          label: AppText.tr('add_description'),
          onTap: widget.onDescriptionSelected,
        ),
      if (!widget.isTaskMode)
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
          iconColor: widget.isImportant ? _fabImportant(context) : null,
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
          enabled: widget.canLock,
          onTap: widget.onLockSelected,
        ),
        _VerticalMenuItem(
          icon: Symbols.delete,
          label: capitalizedDelete,
          iconColor: _fabDestructive(context),
          textColor: _fabDestructive(context),
          onTap: widget.onDeleteSelected,
        ),
      ]);
    }

    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Symbols.label_important,
        fill: widget.isImportant ? 1.0 : 0.0,
        label: AppText.tr('important'),
        iconColor: widget.isImportant ? _fabImportant(context) : null,
        onTap: widget.onImportantSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.search,
        label: AppText.tr(widget.isTaskMode ? 'find_in_tasks' : 'option_find'),
        onTap: widget.onFindSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.drive_file_move,
        label: AppText.tr('option_move'),
        // Nowhere to move to when the app holds no folder at all.
        enabled:
            !_foldersLoaded || _foldersLoading || _foldersFailed || _hasFolders,
        onTap: () => _openMoveMenu(FabVerticalMenu.more),
      ),
      _VerticalMenuItem(
        icon: widget.isLocked ? Symbols.lock_open : Symbols.lock,
        label: widget.isLocked
            ? AppText.tr('option_unlock')
            : AppText.tr('option_lock'),
        enabled: widget.canLock,
        onTap: widget.onLockSelected,
      ),
      _VerticalMenuItem(
        icon: Symbols.delete,
        label: capitalizedDelete,
        iconColor: _fabDestructive(context),
        textColor: _fabDestructive(context),
        onTap: widget.onDeleteSelected,
      ),
    ]);
  }

  Widget _buildVerticalList(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(appPaddingWide),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
