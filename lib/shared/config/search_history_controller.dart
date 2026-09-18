import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The last queries the user searched for, newest first.
///
/// Kept in the same encrypted preferences as the rest of the interface, and
/// capped so the list stays a shortcut rather than a log.
class SearchHistoryController extends ChangeNotifier {
  SearchHistoryController._();

  static final SearchHistoryController instance = SearchHistoryController._();

  static const String _prefKey = 'searchHistory';

  /// How many queries are remembered.
  static const int maxEntries = 8;

  List<String> _entries = <String>[];

  List<String> get entries => List<String>.unmodifiable(_entries);

  Future<void> init() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final String? raw = prefs.getString(_prefKey);
    _entries = _decode(raw);
    notifyListeners();
  }

  /// Remembers [query], moving it to the front if it was already there.
  Future<void> add(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _entries.removeWhere(
      (String entry) => entry.toLowerCase() == trimmed.toLowerCase(),
    );
    _entries.insert(0, trimmed);
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    if (_entries.isEmpty) return;
    _entries = <String>[];
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  Future<void> _persist() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_entries));
  }

  /// A stored list, or nothing when it is missing or unreadable.
  List<String> _decode(String? raw) {
    if (raw == null) return <String>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .take(maxEntries)
            .toList(growable: true);
      }
    } catch (error) {
      debugPrint('SearchHistory: cannot read the stored list ($error)');
    }
    return <String>[];
  }
}