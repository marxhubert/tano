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
