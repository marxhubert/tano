import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/service_locator.dart';

class _Preferences extends Fake implements SecurePreferences {
  _Preferences([this.value]);

  bool? value;
  final writes = <bool>[];
  Completer<void>? writeGate;

  @override
  bool? getBool(String key) => value;

  @override
  Future<void> setBool(String key, bool next) async {
    await writeGate?.future;
    value = next;
    writes.add(next);
  }
}

class _Notes extends Fake implements NotesRepository {
  @override
  Future<List<Note>> loadNotes() async => [];
}

class _Attachments extends Fake implements AttachmentsStore {
  @override
  Future<void> clearMaterialized() async {}
}

Future<void> _mockAppDirectory() async {
  final directory = await Directory.systemTemp.createTemp('tano_fab_side_');
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => directory.path);
  addTearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });
}

void main() {
  test(
    'concurrent loads share one read and notify only actual changes',
    () async {
      final pending = Completer<SecurePreferences>();
      var reads = 0;
      final controller = FabSideController.forTesting(
        preferences: () {
          reads++;
          return pending.future;
        },
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final first = controller.load();
      final second = controller.load();
      expect(second, same(first));
      final preferences = _Preferences(true);
      pending.complete(preferences);
      await Future.wait([first, second]);
      expect(reads, 1);
      expect(controller.onLeft, isTrue);
      expect(notifications, 1);
      await controller.load();
      expect(notifications, 1);
      expect(preferences.writes, isEmpty);
    },
  );

  test('missing preferences default right without a write', () async {
    final preferences = _Preferences();
    final controller = FabSideController.forTesting(
      preferences: () async => preferences,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.onLeft, isFalse);
    expect(preferences.writes, isEmpty);
  });

  for (final choice in [false, true]) {
    test(
      'an explicit $choice choice wins over an older pending load',
      () async {
        final pending = Completer<SecurePreferences>();
        final preferences = _Preferences();
        var reads = 0;
        final controller = FabSideController.forTesting(
          preferences: () => ++reads == 1
              ? pending.future
              : Future<SecurePreferences>.value(preferences),
        );
        addTearDown(controller.dispose);
        final loading = controller.load();
        await Future<void>.delayed(Duration.zero);
        await controller.setOnLeft(choice);
        pending.complete(_Preferences(!choice));
        await loading;
        expect(controller.onLeft, choice);
        expect(preferences.value, choice);
      },
    );
  }

  test('rapid choices persist in order and load waits for them', () async {
    final gate = Completer<void>();
    final preferences = _Preferences()..writeGate = gate;
    final controller = FabSideController.forTesting(
      preferences: () async => preferences,
    );
    addTearDown(controller.dispose);
    final first = controller.setOnLeft(true);
    final second = controller.setOnLeft(false);
    final loaded = controller.load();
    expect(controller.onLeft, isFalse);
    expect(preferences.writes, isEmpty);
    gate.complete();
    await Future.wait([first, second, loaded]);
    expect(preferences.writes, [true, false]);
    expect(preferences.value, isFalse);
    expect(controller.onLeft, isFalse);
  });

  test('a failed load can be retried', () async {
    var reads = 0;
    final controller = FabSideController.forTesting(
      preferences: () async {
        if (++reads == 1) throw StateError('Unavailable');
        return _Preferences(true);
      },
    );
    addTearDown(controller.dispose);
    await expectLater(controller.load(), throwsStateError);
    await controller.load();
    expect(controller.onLeft, isTrue);
  });

  test('reset invalidates an old load and follows pending writes', () async {
    final pending = Completer<SecurePreferences>();
    final gate = Completer<void>();
    final preferences = _Preferences()..writeGate = gate;
    var reads = 0;
    final controller = FabSideController.forTesting(
      preferences: () => ++reads == 1
          ? pending.future
          : Future<SecurePreferences>.value(preferences),
    );
    addTearDown(controller.dispose);
    final loading = controller.load();
    await Future<void>.delayed(Duration.zero);
    final oldChoice = controller.setOnLeft(true);
    final reset = controller.reset();
    expect(controller.onLeft, isFalse);
    pending.complete(_Preferences(true));
    gate.complete();
    await Future.wait([loading, oldChoice, reset]);
    expect(controller.onLeft, isFalse);
    expect(preferences.writes, [true, false]);
    await controller.load();
    expect(controller.onLeft, isFalse);
  });

  test('application initialization reads the saved side', () async {
    await _mockAppDirectory();
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    addTearDown(getIt.reset);
    getIt.registerSingleton<NotesRepository>(_Notes());
    getIt.registerSingleton<AttachmentsStore>(_Attachments());
    final controller = FabSideController.instance;
    await controller.reset();
    final preferences = await SecurePreferences.getInstance();
    await preferences.setBool('fabOnLeft', true);
    expect(controller.onLeft, isFalse);
    await initializeApplication();
    expect(controller.onLeft, isTrue);
  });

  test(
    'settings reset restores right and later loads use fresh preferences',
    () async {
      await _mockAppDirectory();
      SharedPreferences.setMockInitialValues({});
      final controller = FabSideController.instance;
      await controller.setOnLeft(true);
      final model = SettingsViewModel(applyConsent: (_) async {});
      addTearDown(model.dispose);
      await model.performHardReset(deleteData: false, deletePrefs: true);
      expect(controller.onLeft, isFalse);
      final preferences = await SecurePreferences.getInstance();
      expect(preferences.getBool('fabOnLeft'), isFalse);
      await preferences.setBool('fabOnLeft', true);
      await controller.load();
      expect(controller.onLeft, isTrue);
      await controller.reset();
    },
  );
}
