import 'package:flutter/material.dart';
import 'package:tano/shared/config/search_history_controller.dart';

/// Shared pieces of a page's search mode.
///
/// Home and Folder both flip a local search flag, then focus their field on the
/// next frame, and both remember the query when they leave. Keeping the timing
/// and the history rule here is what keeps the two screens behaving the same.

/// Focuses [focusNode] after the frame that shows the search field, so the
/// keyboard opens on a field that is already on screen.
///
/// [isStillActive] is read again inside the callback: a quick enter-then-cancel
/// must not leave an orphaned focused field behind, with the keyboard open on a
/// screen that is no longer searching.
void focusSearchField({
  required FocusNode focusNode,
  required bool Function() isStillActive,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isStillActive()) focusNode.requestFocus();
  });
}

/// Leaves search mode: the query is remembered first — leaving is what makes it
/// a search — then the field is emptied and the keyboard dismissed.
void leaveSearchMode({
  required TextEditingController controller,
  required FocusNode focusNode,
}) {
  SearchHistoryController.instance.add(controller.text);
  controller.clear();
  focusNode.unfocus();
}
