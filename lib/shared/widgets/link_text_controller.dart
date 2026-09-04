import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline note-markdown helpers shared by the editor and the note cards.
///
/// The stored note content stays plain text; these helpers render a light
/// markdown subset (headings, task lists, bullets, bold, inline code and
/// note links) as styled [InlineSpan]s while keeping a strict 1:1 mapping
/// between source characters and rendered characters, so the text cursor
/// stays synchronized.
final RegExp headingLineRegExp = RegExp(r'^#{1,3} ');

/// Whether [line] is a checklist item line (`- [ ] ` or `- [x] `).
bool isTaskLine(String line) =>
    line.startsWith('- [ ] ') || line.startsWith('- [x] ');

/// Whether [line] is a markdown heading line (#, ## or ###).
bool isHeadingLine(String line) => headingLineRegExp.hasMatch(line);

/// The item text after the 6-character checkbox marker.
String taskLineBody(String line) => line.length > 6 ? line.substring(6) : '';

/// Number of checklists in [text]: each run of consecutive task lines counts
/// as one checklist.
int checklistCount(String text) {
  final List<String> lines = text.split('\n');
  int count = 0;
  bool inBlock = false;
  for (final String line in lines) {
    if (isTaskLine(line)) {
      if (!inBlock) {
        count++;
        inBlock = true;
      }
    } else {
      inBlock = false;
    }
  }
  return count;
}

/// Number of note links in [text] (the [[id:title]] pattern).
int linkCountIn(String text) =>
    LinkTextEditingController.linkRegExp.allMatches(text).length;

/// Toggles the checkbox of the task line under [offset] (which must fall in
/// the 6-character marker region) and returns the new full text, or null
/// when [offset] is not on a task checkbox.
String? toggleTaskItemAt(String text, int offset) {
  if (offset < 0 || offset >= text.length) return null;
  final int lineStart =
      offset <= 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
  int lineEnd = text.indexOf('\n', offset);
  if (lineEnd < 0) lineEnd = text.length;
  final String line = text.substring(lineStart, lineEnd);
  if (!isTaskLine(line)) return null;
  final int relative = offset - lineStart;
  if (relative < 0 || relative >= 6) return null;
  final String toggled = line.startsWith('- [x] ')
      ? '- [ ] ${line.substring(6)}'
      : '- [x] ${line.substring(6)}';
  return text.replaceRange(lineStart, lineEnd, toggled);
}

/// Returns the line boundaries and the current title of a checklist title
/// line when [offset] points at its drag handle (the marker region of a
/// heading line directly above a task block), otherwise null.
({int lineStart, int lineEnd, String title})? checklistTitleAt(
  String text,
  int offset,
) {
  if (offset < 0 || offset >= text.length) return null;
  final int lineStart =
      offset <= 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
  int lineEnd = text.indexOf('\n', offset);
  if (lineEnd < 0) lineEnd = text.length;
  final String line = text.substring(lineStart, lineEnd);
  final Match? heading = headingLineRegExp.firstMatch(line);
  if (heading == null) return null;
  final int relative = offset - lineStart;
  if (relative < 0 || relative >= 3) return null;

  // The heading must be directly followed by a task line to be a title.
  final int nextStart = lineEnd + 1;
  if (nextStart > text.length) return null;
  int nextEnd = text.indexOf('\n', nextStart);
  if (nextEnd < 0) nextEnd = text.length;
  if (!isTaskLine(text.substring(nextStart, nextEnd))) return null;

  return (
    lineStart: lineStart,
    lineEnd: lineEnd,
    title: line.substring(heading.group(0)!.length),
  );
}

/// Builds the content and caret position after inserting a checklist.
///
/// The block is a title line (heading with a drag handle, initially empty)
/// followed by one empty item, without blank lines around it. When
/// [hasFocus] is true it is inserted at [caret]; otherwise it is appended
/// at the end of the note.
({String text, int caret}) insertChecklistBlock(
  String text, {
  required bool hasFocus,
  required int caret,
}) {
  const String block = '## \n- [ ] ';
  if (text.isEmpty) {
    return (text: block, caret: block.length);
  }
  if (!hasFocus || caret < 0 || caret > text.length) {
    final String newText =
        text + (text.endsWith('\n') ? '' : '\n') + block;
    return (text: newText, caret: newText.length);
  }
  final String before = text.substring(0, caret);
  final String after = text.substring(caret);
  final String lead = before.isEmpty || before.endsWith('\n') ? '' : '\n';
  final String trail = after.isEmpty || after.startsWith('\n') ? '' : '\n';
  final String newText = before + lead + block + trail + after;
  return (text: newText, caret: before.length + lead.length + block.length);
}

/// Removes checklists that have no item text: every empty item line is
/// dropped, and a block left without any item is removed together with the
/// heading directly above it (its optional title). Runs of more than two
/// blank lines are collapsed to two.
String cleanEmptyChecklists(String text) {
  final List<String> lines = text.split('\n');
  final List<String> result = <String>[];
  int i = 0;
  while (i < lines.length) {
    if (isTaskLine(lines[i])) {
      final int blockStart = i;
      while (i < lines.length && isTaskLine(lines[i])) {
        i++;
      }
      final List<String> block = lines.sublist(blockStart, i);
      final bool allEmpty =
          block.every((String l) => taskLineBody(l).trim().isEmpty);
      if (allEmpty) {
        // Remove the whole empty checklist and its optional title heading.
        if (result.isNotEmpty && isHeadingLine(result.last)) {
          result.removeLast();
        }
      } else {
        for (final String l in block) {
          if (taskLineBody(l).trim().isEmpty) continue;
          result.add(l);
        }
      }
    } else {
      result.add(lines[i]);
      i++;
    }
  }
  if (result.join('\n') == text) return text;

  final List<String> collapsed = <String>[];
  int blankRun = 0;
  for (final String l in result) {
    if (l.trim().isEmpty) {
      blankRun++;
      if (blankRun > 2) continue;
    } else {
      blankRun = 0;
    }
    collapsed.add(l);
  }
  while (collapsed.isNotEmpty && collapsed.last.trim().isEmpty) {
    collapsed.removeLast();
  }
  return collapsed.join('\n');
}

/// Continues a checklist automatically: pressing Enter at the end of a
/// task line inserts a new empty item right below it.
class AutoTaskItemFormatter extends TextInputFormatter {
  const AutoTaskItemFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String oldText = oldValue.text;
    final String newText = newValue.text;
    if (newText.length != oldText.length + 1) return newValue;

    // The inserted character is expected right at the old caret.
    final TextSelection selection = oldValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final int insertAt = selection.baseOffset;
    if (insertAt < 0 || insertAt >= newText.length) return newValue;
    if (newText.substring(0, insertAt) + newText.substring(insertAt + 1) !=
        oldText) {
      return newValue;
    }
    if (newText[insertAt] != '\n') return newValue;

    // The line ending right before the inserted newline must be a task line.
    final int lineStart =
        insertAt <= 0 ? 0 : oldText.lastIndexOf('\n', insertAt - 1) + 1;
    final String line = oldText.substring(lineStart, insertAt);
    if (!isTaskLine(line)) return newValue;
    if (taskLineBody(line).trim().isEmpty) {
      // Pressing Enter on an empty item exits checklist mode: the item line
      // is omitted, leaving one blank line in its place. The behavior is
      // identical whether the checklist is mid-note or at the end of the
      // note, and the caret stays on that blank line so the user can keep
      // typing or insert another checklist right below.
      final String adjusted =
          '${oldText.substring(0, lineStart)}${oldText.substring(insertAt)}';
      return TextEditingValue(
        text: adjusted,
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }

    final String adjusted =
        '${newText.substring(0, insertAt + 1)}- [ ] ${newText.substring(insertAt + 1)}';
    return TextEditingValue(
      text: adjusted,
      selection: TextSelection.collapsed(offset: insertAt + 1 + 6),
    );
  }
}

class LinkTextEditingController extends TextEditingController {
  LinkTextEditingController({
    super.text,
    required this.linkColor,
    Set<String>? activeNoteIds,
  }) : activeNoteIds = activeNoteIds ?? {};

  final Color linkColor;
  Set<String> activeNoteIds;

  bool _suppressAtomicDeletion = false;

  /// Sets [text] without triggering atomic link deletion. Used when restoring
  /// a previous state (undo/redo) so a one-character difference inside a link
  /// is not misinterpreted as a link deletion.
  void setTextForRestore(String text) {
    _suppressAtomicDeletion = true;
    try {
      this.text = text;
    } finally {
      _suppressAtomicDeletion = false;
    }
  }

  static final RegExp linkRegExp = RegExp(r'\[\[([^:]+):([^\]]+)\]\]');
  static final RegExp _headingRegExp = RegExp(r'^(#{1,3}) (.*)$');
  static final RegExp _taskRegExp = RegExp(r'^- \[([ x])\] (.*)$');
  static final RegExp _bulletRegExp = RegExp(r'^- (.*)$');
  static final RegExp _inlineRegExp = RegExp(
    r'\[\[([^:]+):([^\]]+)\]\]|\*\*([^*]+)\*\*|`([^`]+)`',
  );
  static const TextStyle _hiddenStyle =
      TextStyle(fontSize: 0, color: Colors.transparent);

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
    if (_suppressAtomicDeletion) {
      super.value = newValue;
      return;
    }
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
    return buildMarkdownTextSpan(text, style, linkColor, activeNoteIds);
  }

  /// Renders a light markdown subset (headings, task lists, bullets, bold,
  /// inline code and note links) with a strict 1:1 source/rendered character
  /// mapping so the text cursor stays synchronized.
  static TextSpan buildMarkdownTextSpan(
    String text,
    TextStyle? style,
    Color linkColor,
    Set<String> activeNoteIds,
  ) {
    if (text.isEmpty) return TextSpan(style: style);

    final List<InlineSpan> children = <InlineSpan>[];
    final List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final bool isChecklistTitle = i + 1 < lines.length &&
          isHeadingLine(lines[i]) &&
          isTaskLine(lines[i + 1]);
      _appendLine(
          children, lines[i], style, linkColor, activeNoteIds, isChecklistTitle);
      if (i < lines.length - 1) {
        children.add(TextSpan(text: '\n', style: style));
      }
    }
    return TextSpan(style: style, children: children);
  }

  /// Alias kept for compatibility with link-focused call sites and tests.
  static TextSpan buildLinkTextSpan(
    String text,
    TextStyle? style,
    Color linkColor,
    Set<String> activeNoteIds,
  ) {
    return buildMarkdownTextSpan(text, style, linkColor, activeNoteIds);
  }

  static void _appendLine(
    List<InlineSpan> children,
    String line,
    TextStyle? style,
    Color linkColor,
    Set<String> activeNoteIds,
    bool isChecklistTitle,
  ) {
    final TextStyle base = style ?? const TextStyle();

    final Match? task = _taskRegExp.firstMatch(line);
    if (task != null) {
      final bool checked = task.group(1) == 'x';
      // Left margin so the items sit under the title's body, while the
      // title itself stays flush left.
      children.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: const SizedBox(width: 16, height: 1),
      ));
      children.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          size: (base.fontSize ?? 14.4) * 1.3,
          color: checked
              ? linkColor
              : Colors.grey.withValues(alpha: 0.65),
        ),
      ));
      // The 4 remaining marker characters stay hidden (one rendered unit
      // each, so the 1:1 source/rendered character mapping is preserved).
      children.add(TextSpan(text: line.substring(2, 6), style: _hiddenStyle));
      _appendInlineSpans(
          children, line.substring(6), style, linkColor, activeNoteIds);
      return;
    }

    final Match? heading = _headingRegExp.firstMatch(line);
    if (heading != null) {
      final String hashes = heading.group(1)!;
      if (isChecklistTitle) {
        // Checklist title: a drag handle flush against the left edge; the
        // title is typed right next to it, at the content's font size and
        // only slightly bold.
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Transform.translate(
            offset: const Offset(-3, 0),
            child: Icon(
              Icons.drag_indicator,
              size: (base.fontSize ?? 14.4) * 1.2,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ));
        children.add(TextSpan(
          text: '${hashes.substring(1)} ',
          style: _hiddenStyle,
        ));
        final TextStyle titleStyle =
            base.copyWith(fontWeight: FontWeight.w700);
        _appendInlineSpans(children, heading.group(2)!, titleStyle, linkColor,
            activeNoteIds);
        return;
      }
      children.add(TextSpan(text: '$hashes ', style: _hiddenStyle));
      final double scale =
          hashes.length == 1 ? 1.5 : (hashes.length == 2 ? 1.35 : 1.2);
      final TextStyle headingStyle = base.copyWith(
        fontSize: (base.fontSize ?? 14.4) * scale,
        fontWeight: FontWeight.bold,
      );
      _appendInlineSpans(children, heading.group(2)!, headingStyle, linkColor,
          activeNoteIds);
      return;
    }

    final Match? bullet = _bulletRegExp.firstMatch(line);
    if (bullet != null) {
      children.add(TextSpan(text: '•', style: base));
      children.add(TextSpan(text: ' ', style: _hiddenStyle));
      _appendInlineSpans(
          children, bullet.group(1)!, style, linkColor, activeNoteIds);
      return;
    }

    _appendInlineSpans(children, line, style, linkColor, activeNoteIds);
  }

  static void _appendInlineSpans(
    List<InlineSpan> children,
    String body,
    TextStyle? style,
    Color linkColor,
    Set<String> activeNoteIds,
  ) {
    final TextStyle base = style ?? const TextStyle();
    int lastOffset = 0;
    for (final Match match in _inlineRegExp.allMatches(body)) {
      if (match.start > lastOffset) {
        children.add(TextSpan(
          text: body.substring(lastOffset, match.start),
          style: base,
        ));
      }
      final String? linkId = match.group(1);
      final String? linkTitle = match.group(2);
      final String? boldText = match.group(3);
      final String? codeText = match.group(4);
      if (linkId != null && linkTitle != null) {
        _appendLinkSpan(children, match.group(0)!, linkId, linkTitle, base,
            linkColor, activeNoteIds);
      } else if (boldText != null) {
        children.add(TextSpan(text: '**', style: _hiddenStyle));
        children.add(TextSpan(
            text: boldText, style: base.copyWith(fontWeight: FontWeight.bold)));
        children.add(TextSpan(text: '**', style: _hiddenStyle));
      } else if (codeText != null) {
        children.add(TextSpan(text: '`', style: _hiddenStyle));
        children.add(TextSpan(
            text: codeText, style: base.copyWith(fontFamily: 'monospace')));
        children.add(TextSpan(text: '`', style: _hiddenStyle));
      }
      lastOffset = match.end;
    }
    if (lastOffset < body.length) {
      children.add(TextSpan(text: body.substring(lastOffset), style: base));
    }
  }

  static void _appendLinkSpan(
    List<InlineSpan> children,
    String fullMatch,
    String id,
    String rawTitle,
    TextStyle style,
    Color linkColor,
    Set<String> activeNoteIds,
  ) {
    String title = rawTitle;
    // Truncate title to 30 chars
    if (title.length > 30) {
      title = '${title.substring(0, 30)}...';
    }

    final bool isLinkActive = activeNoteIds.contains(id);
    final Color effectiveColor =
        isLinkActive ? linkColor : Colors.grey.withValues(alpha: 0.6);

    final TextStyle linkStyle = style.copyWith(
      color: effectiveColor,
      fontWeight: FontWeight.bold,
      decoration: isLinkActive ? TextDecoration.underline : TextDecoration.none,
      decorationColor: effectiveColor,
      decorationThickness: 0.8,
    );

    // Char 0 ('['): render as icon glyph.
    children.add(
      TextSpan(
        text: String.fromCharCode(Icons.sticky_note_2.codePoint),
        style: linkStyle.copyWith(
          fontFamily: Icons.sticky_note_2.fontFamily,
          package: Icons.sticky_note_2.fontPackage,
          fontSize: (style.fontSize ?? 14.4) * 0.9,
        ),
      ),
    );

    // Chars 1 to start of title: hide.
    final int titleStartInMatch = fullMatch.indexOf(rawTitle);
    if (titleStartInMatch > 1) {
      children.add(
        TextSpan(
          text: fullMatch.substring(1, titleStartInMatch),
          style: _hiddenStyle,
        ),
      );
    }

    // Title chars: show with link style.
    children.add(TextSpan(text: title, style: linkStyle));

    // Truncated remainder of the title: hide.
    final int originalTitleLength = rawTitle.length;
    final int displayedTitleLength = title.length;
    if (originalTitleLength > displayedTitleLength) {
      children.add(
        TextSpan(
          text: rawTitle.substring(displayedTitleLength),
          style: _hiddenStyle,
        ),
      );
    }

    // Suffix ']]': hide.
    children.add(TextSpan(text: ']]', style: _hiddenStyle));
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
