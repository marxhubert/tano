part of 'app_fab.dart';

mixin _FabBarsMixin on _FabStateMixin {
  Widget _buildMainContent(
    BuildContext context,
    bool isExpanded,
    double targetWidth,
  ) {
    if (widget.isFindMode) return _buildFindBar(context);
    if (widget.isSelectionMode) return _buildSelectionBar(context, targetWidth);
    if (widget.isSearchMode) return _buildSearchBar(context);
    if (widget.isEditorMode) {
      return _buildEditorBar(context, isExpanded, targetWidth);
    }
    return _buildHomeBar(context, isExpanded, targetWidth);
  }

  /// Home bar: the "+" opens the extended form with the three creation actions
  /// (folder, note, task) then the reduce chevron.
  Widget _buildHomeBar(
    BuildContext context,
    bool isExpanded,
    double targetWidth,
  ) {
    if (!isExpanded) {
      return _buildDefaultAddButton();
    }
    return _buildHorizontalBar(targetWidth, [
      _EditorAction(
        icon: Symbols.create_new_folder,
        label: AppText.tr('add_folder'),
        onTap: () {
          setState(() => _isManuallyExpanded = false);
          widget.onAddFolder?.call();
        },
      ),
      _EditorAction(
        icon: Symbols.add_notes,
        label: AppText.tr('add_note'),
        onTap: () {
          setState(() => _isManuallyExpanded = false);
          widget.onAdd?.call();
        },
      ),
      _EditorAction(
        icon: Symbols.format_list_bulleted_add,
        label: AppText.tr('add_task'),
        onTap: () {
          setState(() => _isManuallyExpanded = false);
          widget.onAddTask?.call();
        },
      ),
      _EditorAction(
        icon: effectiveOnLeft
            ? Symbols.arrow_back_ios
            : Symbols.arrow_forward_ios,
        label: AppText.tr('reduce'),
        // The chevron fills its box more than the other glyphs: a hair smaller.
        size: 22.0,
        onTap: () => setState(() => _isManuallyExpanded = false),
      ),
    ]);
  }

  Widget _buildEditorBar(
    BuildContext context,
    bool isExpanded,
    double targetWidth,
  ) {
    if (!isExpanded) {
      return IconButton(
        icon: Icon(
          Symbols.more_horiz,
          color: _fabForeground(context),
          weight: 900.0,
        ),
        tooltip: AppText.tr('more'),
        onPressed: _expand,
      );
    }

    return _buildHorizontalBar(targetWidth, [
      _EditorAction(
        icon: Symbols.add_circle,
        label: AppText.tr('add'),
        // Keep the active background while the link sub-menu is open.
        isActive:
            _verticalMenu == FabVerticalMenu.add ||
            _verticalMenu == FabVerticalMenu.link,
        onTap: () {
          // Keep focus so checklist insertion can use the current caret.
          _toggleVerticalMenu(FabVerticalMenu.add);
        },
      ),
      _EditorAction(
        icon: Symbols.palette,
        label: AppText.tr('menu_theme'),
        isActive: _verticalMenu == FabVerticalMenu.color,
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.color);
          widget.onColorLens?.call();
        },
      ),
      _EditorAction(
        icon: Symbols.build_circle,
        label: AppText.tr('more'),
        // Keep the active background while the move sub-menu is open.
        isActive:
            _verticalMenu == FabVerticalMenu.more ||
            _verticalMenu == FabVerticalMenu.move,
        onTap: () {
          _toggleVerticalMenu(FabVerticalMenu.more);
          widget.onMore?.call();
        },
      ),
      _EditorAction(
        icon: effectiveOnLeft
            ? Symbols.arrow_back_ios
            : Symbols.arrow_forward_ios,
        label: AppText.tr('reduce'),
        // The chevron fills its box more than the other glyphs: a hair smaller.
        size: 20.0,
        onTap: () => setState(() {
          _verticalMenu = FabVerticalMenu.none;
          _isManuallyExpanded = false;
        }),
      ),
    ]);
  }

  Widget _buildSelectionBar(BuildContext context, double targetWidth) {
    return _buildHorizontalBar(targetWidth, [
      _EditorAction(
        icon: Symbols.check_circle,
        label: AppText.tr('select_all'),
        onTap: widget.onSelectAll ?? () {},
      ),
      _EditorAction(
        icon: Symbols.circle,
        label: AppText.tr('select_none'),
        onTap: widget.onClearSelection ?? () {},
      ),
      _EditorAction(
        icon: Symbols.drive_file_move,
        label: AppText.tr('option_move'),
        isActive: _verticalMenu == FabVerticalMenu.move,
        // Moving is refused as soon as a folder is selected.
        onTap: widget.canMove
            ? () => _openMoveMenu(FabVerticalMenu.none)
            : null,
      ),
      _EditorAction(
        icon: Symbols.delete,
        label: AppText.tr('delete'),
        color: _fabDestructive(context),
        onTap: widget.canDelete ? (widget.onDelete ?? () {}) : null,
      ),
    ]);
  }

  Widget _buildSearchBar(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => widget.focusNode?.unfocus(),
      child: Container(
        padding: const EdgeInsets.only(
          left: appPaddingWide,
          right: appPaddingTight,
        ),
        child: Row(
          spacing: 8.0,
          children: <Widget>[
            Icon(Symbols.search, color: _fabForeground(context), size: 24.0),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                cursorColor: _fabForeground(context),
                cursorWidth: 1.0,
                cursorHeight: 16.0,
                style: TextStyle(
                  color: _fabForeground(context),
                  fontSize: _fabLabelSize,
                ),
                decoration: InputDecoration(
                  hintText: ' ${AppText.tr('search')}',
                  hintStyle: TextStyle(
                    color: _fabForeground(context).withValues(alpha: .8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: widget.onSearchChanged,
              ),
            ),
            if (widget.controller?.text.isNotEmpty ?? false)
              IconButton(
                icon: Icon(Symbols.backspace, color: _fabForeground(context)),
                tooltip: AppText.tr('clear'),
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
    // The "+" expands into the extended bar.
    return IconButton(
      icon: Icon(Symbols.add_2, color: _fabForeground(context), size: 22.0),
      tooltip: AppText.tr('add'),
      onPressed: _expand,
    );
  }

  Widget _buildFindBar(BuildContext context) {
    final Color navColor = _fabMenuSurface(context);
    final Color fieldColor = Colors.transparent;
    final bool hasQuery = widget.controller?.text.isNotEmpty ?? false;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (hasQuery) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: _buildCounterBox(),
              ),
              _buildNavButton(
                Symbols.chevron_left,
                AppText.tr('previous'),
                widget.onFindPrev,
                navColor,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(left: appPaddingTight),
                child: SizedBox(
                  width: 44.0,
                  child: Center(
                    child: Icon(
                      Symbols.search,
                      color: _fabForeground(context),
                      size: 26.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Container(
            color: fieldColor,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            alignment: Alignment.center,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              cursorColor: _fabForeground(context),
              // One line, centred, scrolled horizontally when it overflows.
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: _fabForeground(context),
                fontSize: _fabLabelSize,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: AppText.tr('find_in_note'),
                hintStyle: TextStyle(
                  color: _fabForeground(context).withValues(alpha: .8),
                ),
                border: InputBorder.none,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.deny('\n'),
              ],
              onChanged: widget.onSearchChanged,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (hasQuery) ...[
              _buildNavButton(
                Symbols.chevron_right,
                AppText.tr('next'),
                widget.onFindNext,
                navColor,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  icon: Icon(Symbols.close, color: _fabForeground(context)),
                  tooltip: AppText.tr('close_button'),
                  onPressed: () => widget.onFindReset?.call(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(
    IconData icon,
    String label,
    VoidCallback? onPressed,
    Color color,
  ) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 44.0,
        child: Material(
          color: color,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(icon, color: _fabForeground(context), size: 28.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBox() {
    final int total = widget.findTotal;
    final int digitCount = total.toString().length;

    // 3+ digits: place "/y" below "x", flush and right-aligned.
    if (digitCount >= 3) {
      return SizedBox(
        width: 48.0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${widget.findCurrent}',
                style: TextStyle(
                  color: _fabForeground(context),
                  fontSize: TanoText.label,
                  fontWeight: FontWeight.bold,
                  height: 0.8,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 0),
                child: Text(
                  '/$total',
                  style: TextStyle(
                    color: _fabForeground(context),
                    fontSize: TanoText.badge,
                    height: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double suffixSize = digitCount == 1 ? 14.0 : 10.0;
    return SizedBox(
      width: 48.0,
      child: Center(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: _fabForeground(context),
              fontSize: TanoText.label,
            ),
            children: <InlineSpan>[
              TextSpan(
                text: '${widget.findCurrent}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '/$total',
                style: TextStyle(fontSize: suffixSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBar(double width, List<Widget> children) {
    // Anchored on the left, the bar grows rightwards: the reduce chevron moves
    // to its head, next to the FAB's origin, keeping its right-pointing glyph.
    final List<Widget> ordered = effectiveOnLeft && children.length > 1
        ? <Widget>[children.last, ...children.take(children.length - 1)]
        : children;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: width,
        child: Row(
          // Split the bar into N equal, gapless, full-height zones, one per
          // action: no spacing, padding or margin between them.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final Widget child in ordered) Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
