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

  @override
  set value(TextEditingValue newValue) {
    // Atomic deletion logic: delete entire link match if one char is removed
    if (newValue.text.length < value.text.length) {
      final int oldSelectionBase = value.selection.baseOffset;
      final int newSelectionBase = newValue.selection.baseOffset;

      // Only handle single character deletion (backspace)
      if (oldSelectionBase - newSelectionBase == 1 && oldSelectionBase > 0) {
        for (final match in linkRegExp.allMatches(value.text)) {
          // If the deleted character was inside a link pattern
          if (oldSelectionBase > match.start && oldSelectionBase <= match.end) {
            final String newText = value.text.replaceRange(match.start, match.end, '');
            super.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: match.start),
            );
            return;
          }
        }
      }
    }
    super.value = newValue;
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
