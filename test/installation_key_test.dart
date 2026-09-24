import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/services/installation_key.dart';

/// A keystore that accepts every write but never remembers anything, like a
/// locked or unsupported platform backend.
class _NonPersistingStorage implements FlutterSecureStorage {
  const _NonPersistingStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

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

  test('a key that secure storage refuses to persist fails loudly', () async {
    final keys = InstallationKey(storage: const _NonPersistingStorage());
    expect(
      keys.databasePassphrase(),
      throwsA(isA<InstallationKeyException>()),
    );
  });
}
