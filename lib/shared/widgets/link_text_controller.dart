import 'package:flutter/material.dart';

class LinkTextEditingController extends TextEditingController {
  LinkTextEditingController({
    super.text,
    required this.linkColor,
    Set<String>? activeNoteIds,
  }) : activeNoteIds = activeNoteIds ?? {};

  final Color linkColor;
  Set<String> activeNoteIds;

  static final RegExp linkRegExp = RegExp(r'\[\[([^:]+):([^\]]+)\]\]');

  int get linkCount => linkRegExp.allMatches(text).length;

  /// Returns [position] snapped to the end of the link that contains it, so a
  /// new link inserted there lands next to the existing link instead of inside
  /// it (which would corrupt both into one malformed link).
  int snapPositionOutOfLink(int position) {
    int snapped = position;
    for (final match in linkRegExp.allMatches(text)) {
      if (position > match.start && position < match.end) {
        snapped = match.end;
      }
    }
    return snapped;
  }

  @override
  set value(TextEditingValue newValue) {
    final String oldText = value.text;
    final String newText = newValue.text;

    // Only single-character deletions can trigger the atomic link removal.
    if (newText.length == oldText.length - 1) {
      final int deletedIndex =
          _deletionIndex(oldText, newText, value.selection.baseOffset);
      if (deletedIndex >= 0) {
        for (final match in linkRegExp.allMatches(oldText)) {
          // Deleting any character inside a link removes the whole link.
          if (deletedIndex >= match.start && deletedIndex < match.end) {
            _removeRange(match.start, match.end);
            return;
          }
          // Deleting the space that directly follows a link removes the link
          // together with that space (the whole insertion in one backspace).
          if (deletedIndex == match.end &&
              deletedIndex < oldText.length &&
              oldText[deletedIndex] == ' ') {
            _removeRange(match.start, match.end + 1);
            return;
          }
        }
      }
    }

    super.value = newValue;
  }

  /// Finds the index of the single character removed between [oldText] and
  /// [newText], using the cursor [oldBase] to disambiguate backspace from
  /// forward-delete. Returns -1 when the change cannot be mapped to a single
  /// character (e.g. a selection replace).
  int _deletionIndex(String oldText, String newText, int oldBase) {
    // Backspace: the character just before the cursor was removed.
    if (oldBase > 0 && oldBase <= oldText.length) {
      if (oldText.substring(0, oldBase - 1) + oldText.substring(oldBase) ==
          newText) {
        return oldBase - 1;
      }
    }
    // Forward delete: the character just after the cursor was removed.
    if (oldBase >= 0 && oldBase < oldText.length) {
      if (oldText.substring(0, oldBase) + oldText.substring(oldBase + 1) ==
          newText) {
        return oldBase;
      }
    }
    // Fallback: first differing character.
    int index = 0;
    while (index < newText.length && oldText[index] == newText[index]) {
      index++;
    }
    return index;
  }

  void _removeRange(int start, int end) {
    super.value = TextEditingValue(
      text: value.text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildLinkTextSpan(text, style, linkColor, activeNoteIds);
  }

  /// Robust helper to build a TextSpan with clickable/styled links.
  /// Each character in the source string corresponds to a character in the rendering
  /// to keep the cursor synchronized (1:1 length mapping).
  static TextSpan buildLinkTextSpan(
    String text,
    TextStyle? style,
    Color linkColor,
    Set<String> activeNoteIds,
  ) {
    if (text.isEmpty) return TextSpan(style: style);

    final List<InlineSpan> children = [];
    int lastOffset = 0;

    for (final Match match in linkRegExp.allMatches(text)) {
      // 1. Plain text before match
      if (match.start > lastOffset) {
        children.add(TextSpan(
          text: text.substring(lastOffset, match.start),
          style: style,
        ));
      }

      final String fullMatch = match.group(0)!;
      final String id = match.group(1)!;
      String title = match.group(2)!;

      // Truncate title to 30 chars
      if (title.length > 30) {
        title = '${title.substring(0, 30)}...';
      }

      final bool isLinkActive = activeNoteIds.contains(id);
      final Color effectiveColor = isLinkActive ? linkColor : Colors.grey.withValues(alpha: 0.6);

      final TextStyle linkStyle = (style ?? const TextStyle()).copyWith(
        color: effectiveColor,
        fontWeight: FontWeight.bold,
        decoration: isLinkActive ? TextDecoration.underline : TextDecoration.none,
        decorationColor: effectiveColor,
        decorationThickness: 0.8,
      );

      // Rendering Strategy: 1:1 Cursor Sync
      // pattern: [[id:title]]
      
      // Char 0 ('['): Render as Icon glyph
      children.add(
        TextSpan(
          text: String.fromCharCode(Icons.sticky_note_2.codePoint),
          style: linkStyle.copyWith(
            fontFamily: Icons.sticky_note_2.fontFamily,
            package: Icons.sticky_note_2.fontPackage,
            fontSize: (style?.fontSize ?? 14.4) * 0.9,
            // Keep underline for the icon too
          ),
        ),
      );

      // Chars 1 to Start of Title: Hide (fontSize 0)
      final int titleStartInMatch = fullMatch.indexOf(match.group(2)!);
      if (titleStartInMatch > 1) {
        children.add(
          TextSpan(
            text: fullMatch.substring(1, titleStartInMatch),
            style: const TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        );
      }

      // Title Chars: Show with linkStyle
      children.add(
        TextSpan(
          text: title,
          style: linkStyle,
        ),
      );

      // Remaining Title characters in source (if title was truncated): Hide
      final int originalTitleLength = match.group(2)!.length;
      final int displayedTitleLength = title.length;
      if (originalTitleLength > displayedTitleLength) {
        children.add(
          TextSpan(
            text: match.group(2)!.substring(displayedTitleLength),
            style: const TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        );
      }

      // Suffix Chars (']]'): Hide
      children.add(
        TextSpan(
          text: ']]',
          style: const TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      );

      lastOffset = match.end;
    }

    // Remaining text
    if (lastOffset < text.length) {
      children.add(TextSpan(
        text: text.substring(lastOffset),
        style: style,
      ));
    }

    return TextSpan(style: style, children: children);
  }

  /// Returns the ID only if tap is on an active link.
  String? getLinkIdAt(int offset) {
    if (offset < 0) return null;
    for (final match in linkRegExp.allMatches(text)) {
      if (offset >= match.start && offset < match.end) {
        final String id = match.group(1)!;
        if (activeNoteIds.contains(id)) {
          return id;
        }
      }
    }
    return null;
  }
}
