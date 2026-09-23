import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/widgets/document_filter.dart';

/// The one owner of the remembered document filter.
///
/// Home and Folder used to read and write the same secure preference key on
/// their own. One controller keeps them in step: a change on either page
/// reaches the other without re-reading the key.
class DocumentFilterController extends ChangeNotifier {
  DocumentFilterController._();

  static final DocumentFilterController instance =
      DocumentFilterController._();

  static const String key = 'documentFilter';

  DocumentFilter _filter = DocumentFilter.all;

  DocumentFilter get filter => _filter;

  /// Reads the stored choice. An equal value does not notify.
  Future<void> load() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final DocumentFilter filter =
        documentFilterFromName(prefs.getString(key)) ?? DocumentFilter.all;
    if (filter == _filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> set(DocumentFilter value) async {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(key, value.name);
  }
}
