import 'package:flutter/material.dart';
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
    double offset = scaffoldGeometry.contentBottom -
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
/// 2. A back button (arrow_back_ios_new) for non-home pages.
/// 3. Unified horizontal padding for AppBar and titles.
/// 4. Unified padding for the body content.
class PageScaffold extends StatefulWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.isHome = false,
    this.headerTrailing,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.scaffoldKey,
    this.onPop,
    this.titleController,
    this.titleHint,
    this.backgroundColor,
    this.titlePaddingLeft,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final bool isHome;
  final Widget? headerTrailing;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onPop;
  final TextEditingController? titleController;
  final String? titleHint;
  final Color? backgroundColor;
  final double? titlePaddingLeft;

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  final ScrollController _scrollController = ScrollController();
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

    final String appBarTitleText =
        (widget.titleController?.text ?? '').isNotEmpty
            ? widget.titleController!.text
            : widget.title;

    return Scaffold(
      key: widget.scaffoldKey,
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: scaffoldBgColor,
        titleSpacing: widget.isHome ? appPaddingLarge : 0.0,
        elevation: _showAppBarTitle ? 2.0 : 0.0,
        shadowColor: _showAppBarTitle
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.transparent,
        shape: _showAppBarTitle
            ? Border(
                bottom: BorderSide(
                  color: getBorderColor(scaffoldBgColor, isDark: isDark),
                  width: 0.5,
                ),
              )
            : null,
        leading: !widget.isHome
            ? Padding(
                padding: const EdgeInsets.only(left: appPaddingSmall),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      size: 20.0, color: textColor),
                  onPressed: widget.onPop ?? () => Navigator.of(context).pop(),
                ),
              )
            : null,
        title: _showAppBarTitle
            ? Text(
                appBarTitleText,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                  letterSpacing: -1.0,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              )
            : null,
        centerTitle: !widget.isHome,
        actions: widget.actions
            ?.map((a) => Padding(
                  padding: const EdgeInsets.only(right: appPaddingSmall),
                  child: a,
                ))
            .toList(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          // Big Title in the body
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              widget.titlePaddingLeft ?? appPaddingLarge,
              appPaddingMedium,
              appPaddingLarge,
              0.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Expanded(
                    child: _buildTitleField(textColor),
                  ),
                  if (widget.headerTrailing != null) widget.headerTrailing!,
                ],
              ),
            ),
          ),
          // Content slivers
          ...widget.slivers,
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget _buildTitleField(Color textColor) {
    if (widget.titleController != null) {
      return TextField(
        controller: widget.titleController,
        maxLines: 3,
        minLines: 1,
        maxLength: 100,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24.0,
          letterSpacing: -2.0,
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
        fontWeight: FontWeight.w800,
        fontSize: 24.0,
        letterSpacing: -2.0,
        color: textColor,
      ),
    );
  }
}
