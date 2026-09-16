import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/features/settings/privacy_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';

void main() {
  const List<String> languages = <String>['en', 'fr', 'mg'];

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
  });

  test('every policy string exists in every supported language', () {
    final List<String> keys = <String>[
      'privacy',
      'privacy_intro',
      'privacy_updated',
      for (final (String title, String body)
          in PrivacyPage.sections) ...<String>[title, body],
    ];

    for (final String lang in languages) {
      for (final String key in keys) {
        final String text = AppText.trFor(lang, key);
        expect(text, isNot(key), reason: 'missing translation: $lang/$key');
        expect(
          text.trim(),
          isNotEmpty,
          reason: 'empty translation: $lang/$key',
        );
      }
    }
  });

  test('the crash section names the consent switch', () {
    final String text = AppText.trFor(
      'en',
      'privacy_crash_body',
      <String, String>{
        'option_bug_report': AppText.trFor('en', 'option_bug_report'),
      },
    );

    expect(text, contains(AppText.trFor('en', 'option_bug_report')));
    expect(text, isNot(contains('{')), reason: 'unresolved placeholder');
  });

  testWidgets('the page renders the intro and every section', (tester) async {
    // A tall surface so the lazy sliver builds the whole policy at once.
    tester.view.physicalSize = const Size(1200.0, 4000.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    await tester.pumpAndSettle();

    expect(find.text(AppText.trFor('en', 'privacy')), findsOneWidget);
    expect(find.text(AppText.trFor('en', 'privacy_intro')), findsOneWidget);
    for (final (String title, _) in PrivacyPage.sections) {
      expect(
        find.text(AppText.trFor('en', title)),
        findsOneWidget,
        reason: 'section $title is missing',
      );
    }
  });
}
