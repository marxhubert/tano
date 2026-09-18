import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/config/service_locator.dart';

class _RetryStore extends AttachmentsStore {
  int attempts = 0;
  @override
  Future<void> clearMaterialized() async {
    if (++attempts == 1) throw StateError('temporary cache failure');
  }
}

void main() {
  test(
    'startup setup retries after partial registration without replacing services',
    () async {
      await getIt.reset();
      addTearDown(getIt.reset);
      final store = _RetryStore();
      getIt.registerSingleton<AttachmentsStore>(store);
      await expectLater(setupServiceLocator(), throwsStateError);
      final repository = getIt<NotesRepository>();
      await setupServiceLocator();
      expect(getIt<NotesRepository>(), same(repository));
      expect(getIt<AttachmentsStore>(), same(store));
      expect(getIt.isRegistered<AuthService>(), isTrue);
      expect(store.attempts, 2);
    },
  );
}
