import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/services/installation_key.dart';

void main() {
  test(
    'concurrent first requests share the persisted installation key',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final keys = InstallationKey();
      final values = await Future.wait(
        List.generate(20, (_) => keys.databasePassphrase()),
      );
      expect(values.toSet(), hasLength(1));
      expect(await InstallationKey().databasePassphrase(), values.first);
    },
  );
}
