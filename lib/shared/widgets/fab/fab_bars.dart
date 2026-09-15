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

  /// Home bar: the "+" opens the extended form with the two creation actions
  /// (folder, note) then the reduce chevron.
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
        icon: Icons.create_new_folder,
        onTap: () {
          setState(() => _isManuallyExpanded = false);
          widget.onAddFolder?.call();
        },
      ),
      _EditorAction(
        icon: Icons.note_add,
        onTap: () {
          setState(() => _isManuallyExpanded = false);
          widget.onAdd?.call();
        },
      ),
      IconButton(
        icon: const Icon(
          Icons.arrow_forward_ios,
          size: 20.0,
          color: Colors.white,
        ),
        onPressed: () => setState(() => _isManuallyExpanded = false),
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
        icon: const Icon(
          Icons.arrow_forward_ios,
          size: 20.0,
          color: Colors.white,
        ),
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
        icon: Icons.select_all,
        label: AppText.tr('select_all'),
        onPressed: widget.onSelectAll ?? () {},
      ),
      _SelectionFabButton(
        icon: Icons.check_box_outline_blank,
        label: AppText.tr('select_none'),
        onPressed: widget.onClearSelection ?? () {},
      ),
      _SelectionFabButton(
        icon: Icons.drive_file_move_outline,
        label: AppText.tr('move'),
        color: Colors.white,
        // Moving is refused as soon as a folder is selected.
        onPressed: widget.canMove ? (widget.onMoveSelected ?? () {}) : null,
      ),
      _SelectionFabButton(
        icon: Icons.delete,
        label: capitalizedDelete,
        color: const Color(0xFFFF8A80),
        onPressed: widget.onDelete ?? () {},
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
    // The "+" expands into the extended bar.
    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: () => setState(() => _isManuallyExpanded = true),
    );
  }

  Widget _buildFindBar(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color navColor = Color.lerp(scheme.primary, Colors.black, 0.1)!;
    final Color fieldColor = scheme.primary.withValues(alpha: 0.35);
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
              _buildNavButton(Icons.chevron_left, widget.onFindPrev, navColor),
            ] else
              SizedBox(
                width: 44.0,
                child: const Center(
                  child: Icon(Icons.search, color: Colors.white, size: 26.0),
                ),
              ),
          ],
        ),
        Expanded(
          child: Container(
            color: fieldColor,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              decoration: InputDecoration(
                hintText: AppText.tr('find_in_note'),
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
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
              _buildNavButton(Icons.chevron_right, widget.onFindNext, navColor),
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => widget.onFindReset?.call(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onPressed, Color color) {
    return SizedBox(
      width: 44.0,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onPressed,
          child: Center(child: Icon(icon, color: Colors.white, size: 28.0)),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  height: 0.8,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 0),
                child: Text(
                  '/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
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
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
            children: <InlineSpan>[
              TextSpan(
                text: '${widget.findCurrent}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
