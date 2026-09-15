import 'package:flutter/foundation.dart';

/// Shared selection state for a screen that lets the user pick several items.
///
/// It owns the "selection mode" flag and the selected ids, and the rule that
/// decides whether an id may be selected at all. Screens only read it and call
/// [enter] / [toggle] / [selectAll] / [clear] / [exit].
class SelectionController extends ChangeNotifier {
  SelectionController({bool Function(String id)? isSelectable})
      : _isSelectable = isSelectable;

  /// Optional rule; when null every id is selectable.
  final bool Function(String id)? _isSelectable;

  bool _isActive = false;
  final Set<String> _ids = <String>{};

  /// Whether selection mode is on.
  bool get isActive => _isActive;

  /// Number of selected ids.
  int get count => _ids.length;

  bool get isEmpty => _ids.isEmpty;
  bool get isNotEmpty => _ids.isNotEmpty;

  /// The selected ids, read-only.
  Set<String> get ids => Set<String>.unmodifiable(_ids);

  bool contains(String id) => _ids.contains(id);

  /// Whether [id] may be selected, per the injected rule.
  bool canSelect(String id) => _isSelectable?.call(id) ?? true;

  /// Enters selection mode with [id] selected. No-op when not selectable.
  void enter(String id) {
    if (!canSelect(id)) return;
    _ids.add(id);
    _isActive = true;
    notifyListeners();
  }

  /// Adds or removes [id]. No-op when not selectable.
  void toggle(String id) {
    if (!canSelect(id)) return;
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
    notifyListeners();
  }

  /// Selects every selectable id of [ids].
  void selectAll(Iterable<String> ids) {
    for (final String id in ids) {
      if (canSelect(id)) _ids.add(id);
    }
    notifyListeners();
  }

  /// Clears the selection but stays in selection mode.
  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }

  /// Clears the selection and leaves selection mode.
  void exit() {
    if (_ids.isEmpty && !_isActive) return;
    _ids.clear();
    _isActive = false;
    notifyListeners();
  }
}
