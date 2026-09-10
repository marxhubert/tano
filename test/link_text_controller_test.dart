import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';

/// Builds a controller with [text] and a collapsed cursor at [cursor].
LinkTextEditingController _linkController(String text, int cursor) {
  final c = LinkTextEditingController(
    text: text,
    linkColor: Colors.amber,
    activeNoteIds: {'id1'},
  );
  c.selection = TextSelection.collapsed(offset: cursor);
  return c;
}

/// Simulates a single-character backspace (collapsed cursor) like the text
/// field does: removes the character just before [cursor] and moves the cursor
/// back by one.
TextEditingValue _backspace(String text, int cursor) {
  return TextEditingValue(
    text: text.substring(0, cursor - 1) + text.substring(cursor),
    selection: TextSelection.collapsed(offset: cursor - 1),
  );
}

void main() {
  group('LinkTextEditingController', () {
    test('markdown rendering preserves 1:1 length mapping', () {
      final texts = <String>[
        '- [ ] Future\n[[id1:Study plan]]\n- [ ] tutu',
        '# Title\n[[id1:${'a' * 40}]]\n- item',
        '**bold** `code` [[id1:title]]',
        'plain text with t u t u no markup',
      ];
      for (final text in texts) {
        final span = LinkTextEditingController.buildMarkdownTextSpan(
          text,
          const TextStyle(fontSize: 14.4),
          Colors.amber,
          {'id1'},
        );
        expect(span.toPlainText().length, text.length,
            reason: '1:1 mapping broken for: $text');
      }
    });

    test('searchOccurrences skips occurrences inside hidden markup', () {
      final c = _linkController('tutu [[tu:id]] tutu', 0);
      // "tu" also matches inside the link id "tu", which is hidden, so it is
      // excluded from the visible matches.
      expect(c.searchOccurrences('tu'), [0, 2, 15, 17]);
    });
    test('one backspace deletes the whole link (cursor after ]])', () {
      final c = _linkController('[[id1:title1]]', 14);

      c.value = _backspace('[[id1:title1]]', 14);

      expect(c.text, '');
    });

    test('one backspace deletes link + trailing space (cursor after space)', () {
      final c = _linkController('[[id1:title1]] ', 15);

      c.value = _backspace('[[id1:title1]] ', 15);

      expect(c.text, '');
    });

    test('backspace inside the link deletes the whole link, not one char', () {
      final c = _linkController('a [[id1:title1]] b', 9);

      c.value = _backspace('a [[id1:title1]] b', 9);

      expect(c.text, 'a  b');
    });

    test('backspace on plain text is unaffected', () {
      final c = _linkController('hello', 5);

      c.value = _backspace('hello', 5);

      expect(c.text, 'hell');
    });

    test('snapPositionOutOfLink moves a cursor inside a link to its end', () {
      final c = _linkController('[[id1:title1]] tail', 14);

      expect(c.snapPositionOutOfLink(9), 14);
      expect(c.snapPositionOutOfLink(14), 14);
      expect(c.snapPositionOutOfLink(0), 0);
      expect(c.snapPositionOutOfLink(15), 15);
    });
  });
}
