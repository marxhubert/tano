import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/secure_preferences.dart';

void main() {
  test(
    'unreadable encrypted preferences are preserved and never silently defaulted',
    () async {
      SharedPreferences.setMockInitialValues({
        'searchHistory': 'enc:v1:not-valid-ciphertext',
      });
      await expectLater(SecurePreferences.getInstance(), throwsFormatException);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('searchHistory'), 'enc:v1:not-valid-ciphertext');
    },
  );
}
