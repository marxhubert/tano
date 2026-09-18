import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/settings/widgets/feedback_section.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/text_scale_controller.dart';

/// In-memory [NotesRepository] so the home can be reached without a database.
class _InMemoryNotesRepository implements NotesRepository {
  final List<Note> notes = <Note>[];

  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<List<Note>> loadTrashNotes() async => <Note>[];
  @override
  Future<void> upsertNote(Note note) async => notes.add(note);
  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => <Note>[];
  @override
  Future<void> deleteAllNotes() async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository());
  });

  test('the text size starts at normal', () async {
    await TextScaleController.instance.init();
    expect(TextScaleController.instance.size, TanoTextSize.normal);
    expect(TextScaleController.instance.scale, 1.0);
  });

  test('the chosen text size is remembered', () async {
    await TextScaleController.instance.setSize(TanoTextSize.large);
    await TextScaleController.instance.init();
    expect(TextScaleController.instance.size, TanoTextSize.large);
    expect(TextScaleController.instance.scale, 1.15);
  });

  test('haptics are on, sound is off by default', () async {
    await FeedbackController.instance.init();
    expect(FeedbackController.instance.haptics, isTrue);
    expect(FeedbackController.instance.sound, isFalse);
  });

  testWidgets('a tick only reaches the platform when the switch is on', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    // The preferences write needs the real event loop; the widget-test zone
    // only runs the fake one.
    await tester.runAsync(() async {
      await FeedbackController.instance.setHaptics(false);
      await FeedbackController.instance.setSound(false);
      await FeedbackController.instance.tap();
    });
    expect(calls, isEmpty);

    await tester.runAsync(() async {
      await FeedbackController.instance.setHaptics(true);
      await FeedbackController.instance.tap();
    });
    expect(
      calls.any((MethodCall call) => call.method == 'HapticFeedback.vibrate'),
      isTrue,
    );
  });

  testWidgets('the chosen size scales the whole app', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(
      () => TextScaleController.instance.setSize(TanoTextSize.large),
    );

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Home));
    expect(MediaQuery.textScalerOf(context).scale(10.0), closeTo(11.5, 0.01));
  });

  testWidgets('the settings section picks a size and toggles the switches', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await TextScaleController.instance.setSize(TanoTextSize.normal);
      await FeedbackController.instance.setHaptics(true);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: FeedbackSection()),
        ),
      ),
    );

    // The four "A" previews, smallest first: the third one is "large".
    await tester.tap(find.text('A').at(2));
    await tester.pump();
    expect(TextScaleController.instance.size, TanoTextSize.large);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(FeedbackController.instance.haptics, isFalse);
  });
}