import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/features/settings/widgets/labs_section.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocaleController.instance.init();
  });

  Future<void> pumpLabs(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tanoTheme(Brightness.light),
        home: Scaffold(
          body: LabsSection(
            viewModel: SettingsViewModel(applyConsent: (_) async {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the labs section gathers the developer tools', (tester) async {
    await pumpLabs(tester);

    expect(find.text(AppText.tr('labs')), findsOneWidget);
    expect(find.text(AppText.tr('labs_sentry_test')), findsOneWidget);
    expect(find.text(AppText.tr('developer_reset')), findsOneWidget);
    expect(find.text(AppText.tr('labs_hint')), findsOneWidget);
  });

  testWidgets('the test error says when crash reports are off', (tester) async {
    await pumpLabs(tester);

    await tester.tap(find.text(AppText.tr('labs_sentry_test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppText.tr('labs_sentry_unavailable')), findsOneWidget);
  });
}
