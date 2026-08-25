import 'package:flutter/material.dart';

class LinkTextEditingController extends TextEditingController {
  LinkTextEditingController({super.text, required this.linkColor, this.onLinkTap});

  final Color linkColor;
  final Function(String id)? onLinkTap;

  static final RegExp linkRegExp = RegExp(r'\[\[([^:]+):([^\]]+)\]\]');

  int get linkCount => linkRegExp.allMatches(text).length;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildLinkTextSpan(text, style, linkColor);
  }

  /// Robust helper to build a TextSpan with clickable/styled links.
  static TextSpan buildLinkTextSpan(String text, TextStyle? style, Color linkColor) {
    if (text.isEmpty) return TextSpan(style: style);
    
    final List<InlineSpan> children = [];
    int lastOffset = 0;

    final TextStyle linkStyle = (style ?? const TextStyle()).copyWith(
      color: linkColor,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
      decorationThickness: 1.0,
    );

    for (final Match match in linkRegExp.allMatches(text)) {
      if (match.start > lastOffset) {
        children.add(TextSpan(
          text: text.substring(lastOffset, match.start),
          style: style,
        ));
      }

      final String fullMatch = match.group(0)!;
      final String id = match.group(1)!;
      String title = match.group(2)!;

      if (title.length > 30) {
        title = '${title.substring(0, 30)}...';
      }

      // To maintain 1:1 cursor sync and avoid offset bugs:
      // We render the first '[' as the Icon character.
      // We render the rest of '[[id:' as invisible text.
      // We render 'title' as visible styled text.
      // We render ']]' as invisible text.

      // 1. First '[' -> Render as Icon using MaterialIcons font
      children.add(
        TextSpan(
          text: String.fromCharCode(Icons.sticky_note_2.codePoint),
          style: linkStyle.copyWith(
            fontFamily: Icons.sticky_note_2.fontFamily,
            package: Icons.sticky_note_2.fontPackage,
            // Adjust size slightly to match text height
            fontSize: (style?.fontSize ?? 14.4) * 0.8,
          ),
        ),
      );

      // 2. Hide everything from second '[' until the start of title
      final int titleStartInMatch = fullMatch.indexOf(match.group(2)!);
      if (titleStartInMatch > 1) {
        children.add(
          TextSpan(
            text: fullMatch.substring(1, titleStartInMatch),
            style: const TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        );
      }

      // 3. Visible title part
      children.add(
        TextSpan(
          text: title,
          style: linkStyle,
        ),
      );

      // 4. Hidden suffix ']]'
      children.add(
        TextSpan(
          text: ']]',
          style: const TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      );

      lastOffset = match.end;
    }

    if (lastOffset < text.length) {
      children.add(TextSpan(
        text: text.substring(lastOffset),
        style: style,
      ));
    }

    return TextSpan(style: style, children: children);
  }

  /// Returns the ID only if tap is clearly on the link.
  String? getLinkIdAt(int offset) {
    if (offset < 0) return null;
    for (final match in linkRegExp.allMatches(text)) {
      // With our 1:1 rendering, any offset within the match range is "on the link".
      if (offset >= match.start && offset < match.end) {
        return match.group(1);
      }
    }
    return null;
  }
}
