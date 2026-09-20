import 'package:tano/shared/widgets/paper_surface.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Places the floating action button flush against the bottom-right corner
/// of the screen (no margin).
class FlushEndFabLocation extends StandardFabLocation {
  static const paddingX = 24.0;
  static const paddingY = 20.0;
  const FlushEndFabLocation();

  @override
  double getOffsetX(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    return scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        paddingX;
  }

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    double offset =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        paddingY;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
    final bool showAppBarTitle = _showAppBarTitle;
    final bool appBarTitleOnLeft =
        showAppBarTitle && widget.alignAppBarTitleLeft;

    return PaperSurface(
      notebook: widget.notebook,
      child: Scaffold(
        key: widget.scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          // When the title slides left (undo/redo/save actions visible), keep a
          // visible gap between the back button and the title.
          titleSpacing: widget.isHome
              ? appPaddingLarge
              : (appBarTitleOnLeft ? appPaddingMedium : 0.0),
          elevation: 0.0,
          shadowColor: showAppBarTitle
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.transparent,
          // Same colour as the cards, with a hairline width.
          shape: showAppBarTitle
              ? Border(
                  bottom: BorderSide(
                    color: cardBorderColor(isDark),
                    width: 0.5,
                  ),
                )
              : null,
          leading: !widget.isHome
              ? IconButton(
                  icon: Icon(
                    Symbols.arrow_back_ios,
                    size: 20.0,
                    color: textColor,
                  ),
                  tooltip: AppText.tr('back'),
                  onPressed: widget.onPop ?? () => Navigator.of(context).pop(),
                )
              : null,
          title: showAppBarTitle
              ? (widget.appBarTitleWidget ??
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
                    ))
              : null,
          centerTitle: !widget.isHome && !appBarTitleOnLeft,
          actions: widget.actions
              ?.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(right: appPaddingSmall),
                  child: a,
                ),
              )
              .toList(),
        ),
        body: _buildBody(textColor, keyboard),
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      ),
    );
  }

  /// The body scroll view.
  ///
  /// With [freezeBody], it is laid out against the height it has when no
  /// keyboard is up, whatever the keyboard does: the empty screens then see
  /// their illustration stay exactly where it is rather than being dragged up
  /// by the shrinking body.
  Widget _buildBody(Color textColor, double keyboard) {
    final Widget scrollView = CustomScrollView(
      key: _bodyKey,
      controller: _scrollController,
      slivers: <Widget>[
        // Big title in the body.
        SliverToBoxAdapter(
          child: SectionTitleLine(
            crossAxisAlignment: widget.headerCrossAxisAlignment,
            titleWidget: widget.titleWidget ?? _buildTitleField(textColor),
            metadata: widget.headerMetadata,
            metadataWidget: widget.headerMetadataWidget,
            padding: EdgeInsets.fromLTRB(
              widget.titlePaddingLeft ?? appPaddingLarge,
              appPaddingMedium,
              appPaddingLarge,
              0.0,
            ),
          ),
        ),
        // Content slivers
        ...widget.slivers,
      ],
    );

    if (!widget.freezeBody) return scrollView;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (keyboard == 0.0 || !constraints.hasBoundedHeight) {
          return scrollView;
        }
        // Laid out against the full height, the body no longer knows the
        // keyboard is there: the content stays where it rests.
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: constraints.maxHeight + keyboard,
          maxHeight: constraints.maxHeight + keyboard,
          child: scrollView,
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
