import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/sort_preferences_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('an empty store falls back to date, ascending', () async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.remove(SortPreferencesController.byKey);
    await prefs.remove(SortPreferencesController.secondaryByKey);
    await prefs.remove(SortPreferencesController.ascendingKey);

    await SortPreferencesController.instance.load();

    expect(SortPreferencesController.instance.by, 'date');
    expect(SortPreferencesController.instance.ascending, isTrue);
  });

  test('title and date also become the secondary criterion', () async {
    final SortPreferencesController controller =
        SortPreferencesController.instance;
    await controller.setBy('alpha');
    expect(controller.secondaryBy, 'alpha');
    // A theme choice keeps the existing tie-break.
    await controller.setBy('theme');
    expect(controller.secondaryBy, 'alpha');
  });

  test('a stored choice survives a reload', () async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(SortPreferencesController.byKey, 'updated');
    await prefs.setBool(SortPreferencesController.ascendingKey, false);

    await SortPreferencesController.instance.load();

    expect(SortPreferencesController.instance.by, 'updated');
    expect(SortPreferencesController.instance.ascending, isFalse);
  });
}
