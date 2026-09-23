import 'package:tano/shared/widgets/paper_surface.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Places the floating action button flush against the bottom-right corner of
/// the content column — or the bottom-left one when [onLeft] is set.
class FlushFabLocation extends StandardFabLocation {
  const FlushFabLocation({this.onLeft = false});

  /// When true the FAB hugs the column's left edge and an expanded bar grows
  /// rightwards instead of leftwards.
  final bool onLeft;

  // The pages build this location on every build. Without equality the Scaffold
  // sees a new location each time and replays its move animation — which scales
  // the FAB — so the FAB blinked on every tap.
  @override
  bool operator ==(Object other) =>
      other is FlushFabLocation && other.onLeft == onLeft;

  @override
  int get hashCode => onLeft.hashCode;

  static const paddingX = 24.0;
  static const paddingY = 20.0;

  @override
  double getOffsetX(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    final double screen = scaffoldGeometry.scaffoldSize.width;
    final double fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final EdgeInsets safe = scaffoldGeometry.minInsets;
    final double sideInset = safe.left > safe.right ? safe.left : safe.right;
    // A compact window — a landscape phone, or a tablet — anchors the FAB to
    // the edge of its content column, safe insets excluded: 12 for a phone, 24
    // for a tablet. A phone in portrait keeps hugging that column as before.
    if (compactChrome(scaffoldGeometry.scaffoldSize)) {
      final double gap = tabletViewport(scaffoldGeometry.scaffoldSize)
          ? 24.0
          : 12.0;
      final double available = screen - sideInset * 2;
      final double content = available < appContentMaxWidth
          ? available
          : appContentMaxWidth;
      final double columnLeft = (screen - content) / 2;
      return onLeft ? columnLeft + gap : columnLeft + content - fabWidth - gap;
    }
    final double available = screen - sideInset * 2;
    final double content = available < appContentMaxWidth
        ? available
        : appContentMaxWidth;
    final double columnLeft = (screen - content) / 2;
    if (onLeft) {
      // The left edge is the anchor: an expanded bar grows rightwards from it.
      return columnLeft + paddingX;
    }
    // The right edge never moves: an expanded bar grows leftwards from it.
    return columnLeft + content - fabWidth - paddingX;
  }

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    final Size screen = scaffoldGeometry.scaffoldSize;
    // A compact window keeps the same gap at the bottom, measured from the safe
    // edge: 12 for a landscape phone, 24 for a tablet. A phone in portrait keeps
    // its old padding.
    final bool compact = compactChrome(screen);
    final double gap = tabletViewport(screen) ? 24.0 : 12.0;
    double offset =
        (compact
            ? screen.height - scaffoldGeometry.minInsets.bottom - gap
            : scaffoldGeometry.contentBottom - paddingY) -
        scaffoldGeometry.floatingActionButtonSize.height;
    if (scaffoldGeometry.snackBarSize.height > 0.0) {
      // Push the FAB up so it stays above the SnackBar.
      offset -= (scaffoldGeometry.snackBarSize.height - 12.0);
    }
    return offset;
  }
}

/// A shared scaffold that handles:
/// 1. A dynamic AppBar that shows the title only when scrolling down.
/// 2. A back button (arrow_back_ios) for non-home pages.
/// 3. Unified horizontal padding for AppBar and titles.
/// 4. Unified padding for the body content.
class PageScaffold extends StatefulWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.isHome = false,
    this.notebook = false,
    this.freezeBody = false,
    this.alignAppBarTitleLeft = false,
    this.headerMetadata,
    this.headerMetadataWidget,
    this.headerCrossAxisAlignment = CrossAxisAlignment.baseline,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.scaffoldKey,
    this.onPop,
    this.titleController,
    this.titleFocusNode,
    this.titleHint,
    this.titleOnChanged,
    this.backgroundColor,
    this.titlePaddingLeft,
    this.titleWidget,
    this.appBarTitleWidget,
    this.condenseHeader = false,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final bool isHome;
  final bool notebook;

  /// When true, the body is laid out against the height it has when no
  /// keyboard is up. The empty screens ask for it: the shrinking body would
  /// otherwise drag their illustration up as soon as the keyboard opens. Kept
  /// still, the illustration reads as a watermark. The lists keep the default,
  /// so their last item still scrolls up out of the keyboard's way.
  final bool freezeBody;

  /// When true (and the app bar title is shown after scrolling), the title
  /// slides to the left, right after the back button, instead of staying
  /// centered. Used by the editor while the undo/redo/save actions appear.
  final bool alignAppBarTitleLeft;

  /// When true, a landscape phone drops the body's title line and moves the
  /// title, with its metadata in front of it, to the app bar. Home keeps its
  /// title line; only a folder asks for this.
  final bool condenseHeader;

  /// Small metadata printed at the right of the body title line.
  final String? headerMetadata;

  /// Tappable metadata for the same slot, when a plain string will not do.
  final Widget? headerMetadataWidget;
  final CrossAxisAlignment headerCrossAxisAlignment;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onPop;
  final TextEditingController? titleController;
  final FocusNode? titleFocusNode;
  final String? titleHint;
  final ValueChanged<String>? titleOnChanged;
  final Color? backgroundColor;
  final double? titlePaddingLeft;

  /// Optional widget to replace the default title text in the body.
  final Widget? titleWidget;

  /// Optional widget to replace the default title text in the AppBar.
  final Widget? appBarTitleWidget;

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  final ScrollController _scrollController = ScrollController();

  // The body is reparented when [PageScaffold.freezeBody] toggles (the empty
  // screens wrap it to hold the illustration's place). Keeping one key makes
  // that a move, not a rebuild, so a cover does not reload on every rebuild.
  final GlobalKey _bodyKey = GlobalKey();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.titleController?.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    widget.titleController?.removeListener(_onTitleChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final bool showTitle = _scrollController.offset > 120;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBgColor =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = getTextColor(scaffoldBgColor);
    // Read here, above the Scaffold: it replaces the body's MediaQuery with one
    // whose bottom view inset is gone, so the body itself can no longer tell
    // that the keyboard is up.
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    final String appBarTitleText =
        (widget.titleController?.text ?? '').isNotEmpty
        ? widget.titleController!.text
        : widget.title;
    // The app bar title appears only once the user scrolls down. When the
    // note is also being edited (undo/redo/save actions visible) the title
    // slides to the left instead of staying centered.
    // A landscape phone has no room for the big title line: the app bar shows
    // the title and its metadata from the first frame. Only the pages that ask
    // for it — a folder, not Home.
    final bool condensed =
        widget.condenseHeader && condensedHeader(MediaQuery.sizeOf(context));
    final bool showAppBarTitle = _showAppBarTitle || condensed;
    final bool appBarTitleOnLeft =
        showAppBarTitle && widget.alignAppBarTitleLeft;

    // A landscape phone reaches both edges: no left/right padding at all. Any
    // other window clears the island and the rounded corners with one symmetric
    // inset, and the app bar keeps its own margins (the island sits at
    // mid-height, out of its way). Portrait and tablets report zero.
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double sideInset = safe.left > safe.right ? safe.left : safe.right;

    return PaperSurface(
      notebook: widget.notebook,
      child: Scaffold(
        key: widget.scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          // The bar itself fills the window, like a site's navbar; only its
          // items are held to the content column, by [appBarContentInset].
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              // When the title slides left (undo/redo/save actions visible), keep a
              // visible gap between the back button and the title.
              titleSpacing: widget.isHome
                  ? appBarContentInset(context)
                  : (appBarTitleOnLeft ? appPaddingMedium : 0.0),
              elevation: 0.0,
              shadowColor: showAppBarTitle
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.transparent,
              // Same colour as the cards, with a hairline width.
              // The paper rules share the warm rule colour, so the scrolled bar
              // takes the accent: it reads as a bar, not as one more rule.
              shape: showAppBarTitle
                  ? Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                    )
                  : null,
              // The back glyph rides the cards' edge: a tap target whose icon
              // sits at its start. 40 = the 24px icon plus the 16px gap the
              // title always kept, so the back-to-title spacing does not move.
              leadingWidth: appBarContentInset(context) + 40.0,
              leading: !widget.isHome
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: appBarContentInset(context),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            Symbols.arrow_back_ios_new,
                            size: 24.0,
                            color: textColor,
                          ),
                        ),
                        tooltip: AppText.tr('back'),
                        onPressed:
                            widget.onPop ?? () => Navigator.of(context).pop(),
                      ),
                    )
                  : null,
              title: showAppBarTitle
                  ? (condensed
                        ? _condensedTitle(textColor, appBarTitleText)
                        : (widget.appBarTitleWidget ??
                              Text(
                                appBarTitleText,
                                maxLines: 1,
                                // Same size as the "Cancel" action.
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: appBarTextSize,
                                  letterSpacing: -0.41,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )))
                  : null,
              // The condensed title leads with its metadata, so it reads from the
              // left rather than from the middle.
              centerTitle: !condensed && !widget.isHome && !appBarTitleOnLeft,
              actions: widget.actions == null
                  ? null
                  : <Widget>[
                      for (final Widget a in widget.actions!)
                        Padding(
                          // A tighter gap between the actions.
                          padding: const EdgeInsets.only(right: 2.0),
                          child: a,
                        ),
                      SizedBox(
                        // The content inset lands once, after the last action.
                        width: appBarContentInset(context) > appPaddingSmall
                            ? appBarContentInset(context) - appPaddingSmall
                            : 0.0,
                      ),
                    ],
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: sideInset),
          child: _buildBody(textColor, keyboard),
        ),
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      ),
    );
  }

  /// The app bar title of a condensed folder: the flags, then the name, on one
  /// line. It is centred while the whole group fits; a longer name keeps the
  /// left edge so it is not cut on both sides.
  Widget _condensedTitle(Color textColor, String title) {
    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: appBarTextSize,
      letterSpacing: -0.41,
      color: textColor,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.headerMetadataWidget != null) ...<Widget>[
              widget.headerMetadataWidget!,
              const SizedBox(width: appPaddingSmall),
            ],
            if (widget.headerMetadata != null) ...<Widget>[
              Text(widget.headerMetadata!, style: titleMetadataStyle(context)),
              const SizedBox(width: appPaddingTight),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ],
        );
        return constraints.maxWidth >= _condensedTitleWidth(title, titleStyle)
            ? Center(child: row)
            : row;
      },
    );
  }

  /// The width the untouched title needs, metadata included, so the decision to
  /// centre does not depend on the layout having happened yet.
  double _condensedTitleWidth(String title, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: title,
        style: style,
        children: widget.headerMetadata == null
            ? null
            : <InlineSpan>[
                TextSpan(
                  text: '  ${widget.headerMetadata}',
                  style: titleMetadataStyle(context),
                ),
              ],
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    // The flags widget cannot be measured before layout; a short allowance keeps
    // the decision honest.
    return painter.width + (widget.headerMetadataWidget != null ? 56.0 : 0.0);
  }

  /// The body scroll view.
  ///
  /// With [freezeBody], it is laid out against the height it has when no
  /// keyboard is up, whatever the keyboard does: the empty screens then see
  /// their illustration stay exactly where it is rather than being dragged up
  /// by the shrinking body.
  Widget _buildBody(Color textColor, double keyboard) {
    // A landscape phone drops the big title line: the app bar carries the title
    // and its metadata, and only the filter control (or the rename field) stays
    // above the list.
    final bool condensed =
        widget.condenseHeader && condensedHeader(MediaQuery.sizeOf(context));
    final Widget scrollView = CustomScrollView(
      key: _bodyKey,
      controller: _scrollController,
      slivers: <Widget>[
        if (!condensed || widget.titleWidget != null)
          SliverToBoxAdapter(
            child: SectionTitleLine(
              crossAxisAlignment: widget.headerCrossAxisAlignment,
              titleWidget: widget.titleWidget ?? _buildTitleField(textColor),
              metadata: condensed ? null : widget.headerMetadata,
              metadataWidget: condensed ? null : widget.headerMetadataWidget,
              padding: EdgeInsets.fromLTRB(
                appSidePad(context, widget.titlePaddingLeft ?? appPaddingLarge),
                appPaddingMedium,
                appSidePad(context, appPaddingLarge),
                0.0,
              ),
            ),
          ),
        // The condensed page has no title line above the list: keep the filter
        // control from touching the app bar.
        if (condensed && widget.titleWidget == null)
          const SliverToBoxAdapter(child: SizedBox(height: appPaddingMedium)),
        // Content slivers
        ...widget.slivers,
      ],
    );

    // One content column, centred: on a tablet the page reads like the site
    // instead of stretching edge to edge.
    final Widget body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: appContentMaxWidth),
        child: scrollView,
      ),
    );

    if (!widget.freezeBody) return body;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (keyboard == 0.0 || !constraints.hasBoundedHeight) {
          return body;
        }
        // Laid out against the full height, the body no longer knows the
        // keyboard is there: the content stays where it rests.
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: constraints.maxHeight + keyboard,
          maxHeight: constraints.maxHeight + keyboard,
          child: body,
        );
      },
    );
  }

  Widget _buildTitleField(Color textColor) {
    if (widget.titleController != null) {
      return TextField(
        controller: widget.titleController,
        focusNode: widget.titleFocusNode,
        maxLines: 3,
        minLines: 1,
        maxLength: 100,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        onChanged: widget.titleOnChanged,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: TanoText.pageTitle,
          fontFamily: 'TanoSerif',
          letterSpacing: -0.41,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: widget.titleHint,
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          counter: const Offstage(),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      );
    }
    return Text(
      widget.title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: TanoText.pageTitle,
        fontFamily: 'TanoSerif',
        letterSpacing: -0.41,
        color: textColor,
      ),
    );
  }
}
