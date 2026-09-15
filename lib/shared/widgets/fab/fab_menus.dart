part of 'app_fab.dart';

mixin _FabMenusMixin on _FabStateMixin {
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
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15)),
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
            _sortCriteria == LinkSortCriteria.date
                ? Icons.sort
                : Icons.sort_by_alpha,
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
            _isAscending
                ? Icons.keyboard_double_arrow_down
                : Icons.keyboard_double_arrow_up,
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
            style: const TextStyle(color: Colors.white, fontSize: 17),
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
                    border: Border.all(color: Colors.white30, width: 1.0),
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
                          child: Icon(
                            Icons.check_circle,
                            color: tanoAmber,
                            size: 20.0,
                          ),
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
    // On the folder page the "+" offers a cover image or a new note.
    if (widget.isFolderMode) {
      return _buildVerticalList([
        _VerticalMenuItem(
          icon: Icons.crop_original,
          label: AppText.tr('option_image'),
          onTap: widget.onImageSelected,
        ),
        _VerticalMenuItem(
          icon: Icons.note_add,
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
        icon: Symbols.sticky_note_2,
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
          icon: Icons.edit_outlined,
          label: AppText.tr('edit'),
          onTap: widget.onEditTitle,
        ),
        _VerticalMenuItem(
          icon: widget.isLocked ? Icons.lock_open : Icons.lock_outline,
          label: widget.isLocked
              ? AppText.tr('option_unlock')
              : AppText.tr('option_lock'),
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

    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Symbols.label_important,
        fill: widget.isImportant ? 1.0 : 0.0,
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
        icon: widget.isLocked ? Icons.lock_open : Icons.lock_outline,
        label: widget.isLocked ? AppText.tr('option_unlock') : AppText.tr('option_lock'),
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
}
