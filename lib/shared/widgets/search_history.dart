import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/theme.dart';

/// True while a search screen should offer the recent searches instead of its
/// results: the field is open, still empty, and there is something to offer.
///
/// Home and a folder share it, so both search screens behave the same.
bool showSearchHistory({required bool isSearchMode, required bool hasQuery}) =>
    isSearchMode &&
    !hasQuery &&
    SearchHistoryController.instance.entries.isNotEmpty;

/// The "Clear" action, in the metadata slot of a search screen's title line.
Widget clearSearchHistoryButton(BuildContext context) {
  return TextButton(
    onPressed: () => SearchHistoryController.instance.clear(),
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(AppText.tr('clear'), style: titleMetadataStyle(context)),
  );
}

/// The recent searches, one ink-ruled row each, the rules flush with the
/// content's edges on both sides.
Widget searchHistorySliver(
  BuildContext context, {
  required ValueChanged<String> onSelected,
}) {
  final List<String> entries = SearchHistoryController.instance.entries;
  return SliverList(
    delegate: SliverChildListDelegate(<Widget>[
      for (int i = 0; i < entries.length; i++) ...<Widget>[
        if (i > 0)
          Divider(
            height: 1.0,
            thickness: 0.3,
            color: primaryTextColor(context),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(appBorderRadius),
          onTap: () => onSelected(entries[i]),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: appPaddingSmall,
              vertical: appPaddingMedium,
            ),
            child: Text(
              entries[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: TanoText.body,
                color: primaryTextColor(context),
              ),
            ),
          ),
        ),
      ],
    ]),
  );
}
