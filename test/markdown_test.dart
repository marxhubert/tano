import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';

const TextStyle _style = TextStyle(fontSize: 14.4);
const Color _linkColor = Color(0xFFFF9800);

/// Concatenates every span in order, so the strict 1:1 source/rendered
/// character mapping can be verified. A [WidgetSpan] counts as one
/// placeholder character (the object replacement character).
String _flatten(InlineSpan span) {
  final StringBuffer buffer = StringBuffer();
  void visit(InlineSpan s) {
    if (s is TextSpan) {
      buffer.write(s.text ?? '');
    } else if (s is WidgetSpan) {
      buffer.write('\uFFFC');
    }
    if (s is TextSpan) {
      for (final InlineSpan child in s.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(span);
  return buffer.toString();
}

/// Collects the spans in render order (the root container first).
List<InlineSpan> _collectSpans(InlineSpan span) {
  final List<InlineSpan> result = <InlineSpan>[];
  void visit(InlineSpan s) {
    result.add(s);
    if (s is TextSpan) {
      for (final InlineSpan child in s.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(span);
  return result;
}

void main() {
  group('toggleTaskItemAt', () {
    test('toggles unchecked to checked inside the marker region', () {
      expect(toggleTaskItemAt('- [ ] item', 0), '- [x] item');
      expect(toggleTaskItemAt('- [ ] item', 5), '- [x] item');
    });

    test('toggles checked back to unchecked', () {
      expect(toggleTaskItemAt('- [x] item', 0), '- [ ] item');
    });

    test('ignores taps outside the marker region', () {
      expect(toggleTaskItemAt('- [ ] item', 6), isNull);
      expect(toggleTaskItemAt('plain text', 0), isNull);
      expect(toggleTaskItemAt('', 0), isNull);
    });

    test('toggles only the targeted line in multi-line text', () {
      const String text = '- [ ] one\n- [x] two';
      // The second line starts at index 10; the tap is on its marker.
      final String? toggled = toggleTaskItemAt(text, 10);
      expect(toggled, '- [ ] one\n- [ ] two');
    });
  });

  group('checklistTitleAt', () {
    test('finds the title line of a checklist', () {
      final info = checklistTitleAt('## Mon titre\n- [ ] x', 0);
      expect(info, isNotNull);
      expect(info!.title, 'Mon titre');
      expect(info.lineStart, 0);
      expect(info.lineEnd, 12);
    });

    test('returns null for a heading not above a checklist', () {
      expect(checklistTitleAt('## Plain\n\ntext', 0), isNull);
    });

    test('returns null outside the handle region', () {
      expect(checklistTitleAt('## Mon titre\n- [ ] x', 5), isNull);
    });
  });

  group('insertChecklistBlock', () {
    test('inserts a title line and one item into empty text', () {
      final r = insertChecklistBlock('', hasFocus: true, caret: 0);
      expect(r.text, '## \n- [ ] ');
      expect(r.caret, 10);
    });

    test('appends at the end when unfocused', () {
      final r = insertChecklistBlock('abc', hasFocus: false, caret: -1);
      expect(r.text, 'abc\n## \n- [ ] ');
      expect(r.caret, r.text.length);
    });

    test('inserts at the caret without blank lines around', () {
      final r = insertChecklistBlock('ab\ncd', hasFocus: true, caret: 3);
      expect(r.text, 'ab\n## \n- [ ] \ncd');
      expect(r.caret, 13);
    });

    test('inserts at the start with a trailing line break', () {
      final r = insertChecklistBlock('abc', hasFocus: true, caret: 0);
      expect(r.text, '## \n- [ ] \nabc');
      expect(r.caret, 10);
    });
  });

  group('cleanEmptyChecklists', () {
    test('removes a lone empty checklist', () {
      expect(cleanEmptyChecklists('- [ ] '), '');
      expect(cleanEmptyChecklists('a\n\n- [ ] '), 'a');
    });

    test('removes an empty checklist together with its title heading', () {
      expect(cleanEmptyChecklists('## Title\n- [ ] \n- [x] '), '');
    });

    test('keeps a filled checklist and drops only its empty items', () {
      expect(
        cleanEmptyChecklists('## Title\n- [ ] done\n- [ ] '),
        '## Title\n- [ ] done',
      );
    });

    test('keeps checked items that have text', () {
      expect(cleanEmptyChecklists('- [x] done'), '- [x] done');
    });

    test('leaves plain content untouched', () {
      expect(cleanEmptyChecklists('hello\nworld'), 'hello\nworld');
    });

    test('collapses blank lines left behind by a removed checklist', () {
      expect(cleanEmptyChecklists('a\n\n- [ ] \n\nb'), 'a\n\n\nb');
    });

    test('leaves text without checklists untouched', () {
      expect(cleanEmptyChecklists('a\n\n\n\nb'), 'a\n\n\n\nb');
    });
  });

  group('buildMarkdownTextSpan', () {
    test('keeps a strict 1:1 source/rendered character mapping', () {
      const String text =
          '## Title\n\n- [ ] item\n- [x] done\n\n**bold** and `code` [[1:Link]]\nplain';
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        text,
        _style,
        _linkColor,
        <String>{'1'},
      );
      expect(_flatten(span).length, text.length);
    });

    test('renders the checkbox glyph as the first character of a task line', () {
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        '- [ ] item',
        _style,
        _linkColor,
        <String>{},
      );
      final List<InlineSpan> spans = _collectSpans(span);
      // Left margin for the items, so the title stays flush left.
      expect(spans[1], isA<WidgetSpan>());
      final WidgetSpan indent = spans[1] as WidgetSpan;
      expect(indent.child, isA<SizedBox>());
      expect((indent.child as SizedBox).width, 16);
      final WidgetSpan box = spans[2] as WidgetSpan;
      expect(box.alignment, PlaceholderAlignment.middle);
      expect(box.child, isA<Icon>());
      expect((box.child as Icon).icon, Icons.check_box_outline_blank);
      expect((box.child as Icon).size, greaterThan(_style.fontSize!));
      // The 4 hidden marker characters keep the 1:1 mapping.
      expect((spans[3] as TextSpan).text, '[ ] ');
    });

    test('renders a filled check_box icon for - [x]', () {
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        '- [x] item',
        _style,
        _linkColor,
        <String>{},
      );
      final List<InlineSpan> spans = _collectSpans(span);
      expect(spans[2], isA<WidgetSpan>());
      expect(((spans[2] as WidgetSpan).child as Icon).icon, Icons.check_box);
    });

    test('renders a drag handle on a checklist title line', () {
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        '## Mon titre\n- [ ] x',
        _style,
        _linkColor,
        <String>{},
      );
      final List<InlineSpan> spans = _collectSpans(span);
      expect(spans[1], isA<WidgetSpan>());
      final Widget handle = (spans[1] as WidgetSpan).child;
      expect(handle, isA<Transform>());
      expect(((handle as Transform).child as Icon).icon, Icons.drag_indicator);
      expect((spans[2] as TextSpan).text, '# ');
      expect((spans[3] as TextSpan).text, 'Mon titre');
      // The title uses the content's font size, only slightly bold.
      expect((spans[3] as TextSpan).style?.fontSize, _style.fontSize);
      expect((spans[3] as TextSpan).style?.fontWeight, FontWeight.w700);
    });

    test('hides the heading marker and styles the heading text', () {
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        '## Title',
        _style,
        _linkColor,
        <String>{},
      );
      final List<InlineSpan> spans = _collectSpans(span);
      expect((spans[1] as TextSpan).text, '## ');
      expect((spans[1] as TextSpan).style?.fontSize, 0);
      expect((spans[2] as TextSpan).text, 'Title');
      expect((spans[2] as TextSpan).style?.fontWeight, FontWeight.bold);
      expect((spans[2] as TextSpan).style!.fontSize, greaterThan(_style.fontSize!));
    });

    test('hides bold markers and bolds the content', () {
      final TextSpan span = LinkTextEditingController.buildMarkdownTextSpan(
        'a **b** c',
        _style,
        _linkColor,
        <String>{},
      );
      final List<InlineSpan> spans = _collectSpans(span);
      expect((spans[1] as TextSpan).text, 'a ');
      expect((spans[2] as TextSpan).text, '**');
      expect((spans[2] as TextSpan).style?.fontSize, 0);
      expect((spans[3] as TextSpan).text, 'b');
      expect((spans[3] as TextSpan).style?.fontWeight, FontWeight.bold);
    });
  });

  group('AutoTaskItemFormatter', () {
    const AutoTaskItemFormatter formatter = AutoTaskItemFormatter();

    test('continues the checklist on Enter at the end of an item', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '- [ ] item',
          selection: TextSelection.collapsed(offset: 10),
        ),
        const TextEditingValue(
          text: '- [ ] item\n',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(result.text, '- [ ] item\n- [ ] ');
      expect(result.selection.baseOffset, 17);
    });

    test('continues the checklist on Enter in the middle of the note', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '- [ ] x\nmore',
          selection: TextSelection.collapsed(offset: 7),
        ),
        const TextEditingValue(
          text: '- [ ] x\n\nmore',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(result.text, '- [ ] x\n- [ ] \nmore');
      expect(result.selection.baseOffset, 14);
    });

    test('omits the empty item on Enter', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '- [ ] ',
          selection: TextSelection.collapsed(offset: 6),
        ),
        const TextEditingValue(
          text: '- [ ] \n',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });

    test('keeps one blank line below a checklist at the end of the note', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'World\n## \n- [ ] ',
          selection: TextSelection.collapsed(offset: 16),
        ),
        const TextEditingValue(
          text: 'World\n## \n- [ ] \n',
          selection: TextSelection.collapsed(offset: 17),
        ),
      );
      // The empty item is omitted, one blank line stays below the checklist
      // and the caret remains on it (same behavior as mid-note).
      expect(result.text, 'World\n## \n');
      expect(result.selection.baseOffset, 10);
    });

    test('omits a middle empty item, keeping one blank line', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'a\n- [ ] \nb',
          selection: TextSelection.collapsed(offset: 8),
        ),
        const TextEditingValue(
          text: 'a\n- [ ] \n\nb',
          selection: TextSelection.collapsed(offset: 9),
        ),
      );
      expect(result.text, 'a\n\nb');
      expect(result.selection.baseOffset, 2);
    });

    test('does nothing for Enter on a plain line', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'plain',
          selection: TextSelection.collapsed(offset: 5),
        ),
        const TextEditingValue(
          text: 'plain\n',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result.text, 'plain\n');
    });

    test('does nothing for non-newline insertions', () {
      final TextEditingValue result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '- [ ] item',
          selection: TextSelection.collapsed(offset: 9),
        ),
        const TextEditingValue(
          text: '- [ ] itemx',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      expect(result.text, '- [ ] itemx');
    });
  });
}
