import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Checklist editing shares the document controller with save, undo/redo,
/// insertion and find. Row controllers only own the visible caret/composition.
class TaskListEditor extends StatefulWidget {
  const TaskListEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onTapText,
    this.autofocus = false,
    this.onCaretChanged,
  });
  final LinkTextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onTapText;
  final bool autofocus;
  final VoidCallback? onCaretChanged;

  @override
  State<TaskListEditor> createState() => TaskListEditorState();
}

class _Row {
  _Row(TaskItem item)
    : controller = LinkTextEditingController(
        text: item.text,
        linkColor: tanoAmber,
      ),
      done = item.done;
  final key = GlobalKey();
  final LinkTextEditingController controller;
  final focus = FocusNode();
  bool done;
  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class TaskListEditorState extends State<TaskListEditor> {
  final List<_Row> _rows = [];
  bool _writing = false;
  bool _completedExpanded = true;
  late String _lastContent;
  TextSelection? _lastRevealSelection;

  @override
  void initState() {
    super.initState();
    _lastContent = widget.controller.text;
    _replaceRows();
    widget.controller.addListener(_receive);
    if (widget.autofocus) _focus(_rows.first);
  }

  void _listenRow(_Row row) {
    row.controller.addListener(() => _syncSelection(row));
    row.focus.addListener(() {
      if (row.focus.hasFocus) widget.onCaretChanged?.call();
    });
  }

  void _replaceRows() {
    final items = TaskContent.parse(widget.controller.text);
    final old = List<_Row>.of(_rows);
    _rows.clear();
    for (final item in items.isEmpty ? [const TaskItem('')] : items) {
      final row = _Row(item);
      _listenRow(row);
      _rows.add(row);
    }
    // EditableText still uses its controller until this frame is rebuilt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in old) {
        row.dispose();
      }
    });
  }

  void _receive() {
    if (_writing) return;
    final contentChanged = _lastContent != widget.controller.text;
    final hadFocus = _rows.any((row) => row.focus.hasFocus);
    if (contentChanged) {
      _lastContent = widget.controller.text;
      setState(_replaceRows);
    } else {
      setState(() {}); // Link availability and search highlighting.
    }
    // External find/insertion chooses a source offset; reveal its row.
    final selection = widget.controller.selection;
    final reveal = contentChanged || selection != _lastRevealSelection;
    _lastRevealSelection = selection;
    if (selection.isValid && selection.baseOffset >= 0) {
      var offset = 0;
      for (final row in _rows) {
        final end = offset + 6 + row.controller.text.length;
        if (selection.baseOffset <= end) {
          if (row.done && !selection.isCollapsed) _completedExpanded = true;
          _writing = true;
          row.controller.selection = TextSelection(
            baseOffset: (selection.baseOffset - offset - 6).clamp(
              0,
              row.controller.text.length,
            ),
            extentOffset: (selection.extentOffset - offset - 6).clamp(
              0,
              row.controller.text.length,
            ),
          );
          _writing = false;
          if (contentChanged && hadFocus) {
            _focus(row, preserveSelection: true);
          } else if (!selection.isCollapsed && reveal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final context = row.key.currentContext;
              if (context != null) widget.onCaretChanged?.call();
            });
          }
          break;
        }
        offset = end + 1;
      }
    }
  }

  void _syncSelection(_Row row) {
    if (_writing || !row.focus.hasFocus || !_rows.contains(row)) return;
    // Text changes are committed by onChanged; do not map a caret against
    // the previous document length during the controller notification.
    if (_rows
            .map((r) => TaskItem(r.controller.text, done: r.done).markdown)
            .join('\n') !=
        widget.controller.text) {
      return;
    }
    widget.onCaretChanged?.call();
    final selection = row.controller.selection;
    if (!selection.isValid) return;
    var offset = 6;
    for (final other in _rows) {
      if (identical(other, row)) break;
      offset += other.controller.text.length + 7;
    }
    _writing = true;
    widget.controller.selection = TextSelection(
      baseOffset: offset + selection.baseOffset,
      extentOffset: offset + selection.extentOffset,
    );
    _writing = false;
  }

  void _publish() {
    _lastContent = _rows
        .map((row) => TaskItem(row.controller.text, done: row.done).markdown)
        .join('\n');
    _writing = true;
    widget.controller.setTextForRestore(_lastContent);
    _writing = false;
    for (final row in _rows) {
      _syncSelection(row);
    }
    widget.onChanged();
    setState(() {});
  }

  void _focus(_Row row, {bool preserveSelection = false, int? caret}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rows.contains(row)) return;
      row.focus.requestFocus();
      if (!preserveSelection) {
        row.controller.selection = TextSelection.collapsed(
          offset: (caret ?? row.controller.text.length).clamp(
            0,
            row.controller.text.length,
          ),
        );
      }
      widget.onCaretChanged?.call();
    });
  }

  BuildContext? get focusedRowContext {
    for (final row in _rows) {
      if (row.focus.hasFocus) return row.key.currentContext;
    }
    return null;
  }

  /// The selected row can differ from the focused widget during find mode.
  BuildContext? get selectedRowContext {
    final offset = widget.controller.selection.baseOffset;
    if (offset < 0) return null;
    var start = 0;
    for (final row in _rows) {
      final end = start + row.controller.text.length + 6;
      if (offset <= end) return row.key.currentContext;
      start = end + 1;
    }
    return null;
  }

  void addItem() {
    final empty = _rows.where(
      (row) => !row.done && row.controller.text.trim().isEmpty,
    );
    if (empty.isNotEmpty) {
      _focus(empty.first);
      return;
    }
    final row = _Row(const TaskItem(''));
    _listenRow(row);
    _rows.add(row);
    _publish();
    _focus(row);
  }

  /// Inserts through the row controller so even an empty draft retains its
  /// checkbox prefix and links share the note editor's atomic link behavior.
  void insertText(String text) {
    final offset = widget.controller.selection.baseOffset;
    var start = 0;
    _Row target = _rows.first;
    var caret = 0;
    for (final row in _rows) {
      final end = start + row.controller.text.length + 6;
      if (offset <= end) {
        target = row;
        caret = (offset - start - 6).clamp(0, row.controller.text.length);
        break;
      }
      start = end + 1;
    }
    caret = target.controller.snapPositionOutOfLink(caret);
    target.controller.value = TextEditingValue(
      text: target.controller.text.replaceRange(caret, caret, text),
      selection: TextSelection.collapsed(offset: caret + text.length),
    );
    _publish();
    _focus(target, caret: caret + text.length);
  }

  void _change(_Row row, String text) {
    if (text.contains('\n')) {
      // Enter splits at the caret; multi-line paste creates independent rows.
      final caret = row.controller.selection.baseOffset.clamp(0, text.length);
      final beforeCaret = text.substring(0, caret).split('\n');
      final focusIndex = beforeCaret.length - 1;
      final lines = text.split('\n');
      if (lines.every((line) => line.trim().isEmpty)) {
        row.controller.text = '';
        _focus(row, caret: 0);
        _publish();
        return;
      }
      row.controller.text = lines.first;
      var index = _rows.indexOf(row) + 1;
      final inserted = <_Row>[row];
      _Row last = row;
      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty &&
            _rows.any((r) => !r.done && r.controller.text.trim().isEmpty)) {
          continue;
        }
        last = _Row(TaskItem(line, done: row.done));
        final added = last;
        _listenRow(added);
        _rows.insert(index++, added);
        inserted.add(added);
      }
      _focus(
        inserted[focusIndex.clamp(0, inserted.length - 1)],
        caret: beforeCaret.last.length,
      );
    }
    _publish();
  }

  void _remove(_Row row) {
    final index = _rows.indexOf(row);
    if (_rows.length == 1) {
      row.controller.clear();
      row.done = false;
    } else {
      _rows.remove(row);
      WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
    }
    _publish();
    _focus(_rows[(index - 1).clamp(0, _rows.length - 1)]);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_receive);
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Widget _buildRow(_Row row, {int? reorderIndex}) {
    row.controller.activeNoteIds = widget.controller.activeNoteIds;
    row.controller.searchQuery = widget.controller.searchQuery;
    var precedingMatches = 0;
    for (final other in _rows) {
      if (identical(other, row)) break;
      precedingMatches += other.controller
          .searchOccurrences(widget.controller.searchQuery)
          .length;
    }
    row.controller.searchCurrentIndex =
        widget.controller.searchCurrentIndex - precedingMatches;
    row.controller.searchBlinkValue = widget.controller.searchBlinkValue;
    return Focus(
      key: row.key,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            row.controller.text.isEmpty &&
            _rows.length > 1) {
          _remove(row);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reorderIndex != null)
            ReorderableDragStartListener(
              index: reorderIndex,
              child: const SizedBox(
                width: 24,
                height: 48,
                child: Icon(Symbols.drag_indicator, size: 20),
              ),
            )
          else
            const SizedBox(width: 24),
          SizedBox(
            width: 24,
            height: 48,
            child: Checkbox(
              value: row.done,
              semanticLabel: row.controller.text,
              onChanged: row.controller.text.trim().isEmpty
                  ? null
                  : (value) {
                      final hadFocus = row.focus.hasFocus;
                      row.done = value!;
                      row.focus.unfocus();
                      _publish();
                      if (hadFocus) {
                        final active = _rows.where((item) => !item.done);
                        if (active.isNotEmpty) _focus(active.first);
                      }
                    },
            ),
          ),
          Expanded(
            child: TextField(
              controller: row.controller,
              focusNode: row.focus,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: TanoText.label,
                height: 1.8,
                decoration: row.done ? TextDecoration.lineThrough : null,
              ),
              decoration: InputDecoration(
                hintText: AppText.tr('add_task_item'),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (text) => _change(row, text),
              onTap: () {
                _syncSelection(row);
                widget.onTapText();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.close, size: 18),
            tooltip: AppText.tr('delete'),
            onPressed: () => _remove(row),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _rows.where((row) => row.done).toList();
    final active = _rows.where((row) => !row.done).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding: EdgeInsets.zero,
          onReorderItem: (oldIndex, newIndex) {
            final moved = active.removeAt(oldIndex);
            active.insert(newIndex, moved);
            var index = 0;
            for (var i = 0; i < _rows.length; i++) {
              if (!_rows[i].done) _rows[i] = active[index++];
            }
            _publish();
          },
          children: [
            for (var i = 0; i < active.length; i++)
              _buildRow(active[i], reorderIndex: i),
          ],
        ),
        TextButton.icon(
          onPressed: addItem,
          icon: const Icon(Symbols.add),
          label: Text(AppText.tr('add_task_item')),
        ),
        if (completed.isNotEmpty) ...[
          const Divider(key: ValueKey('completed-task-divider')),
          Semantics(
            button: true,
            expanded: _completedExpanded,
            child: InkWell(
              key: const ValueKey('completed-task-header'),
              onTap: () =>
                  setState(() => _completedExpanded = !_completedExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _completedExpanded ? 0.25 : 0,
                      duration: TanoMotion.base,
                      child: Icon(
                        Symbols.chevron_forward,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppText.tr('completed_tasks'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_completedExpanded) ...[
            for (final row in completed) _buildRow(row),
          ],
        ],
      ],
    );
  }
}
