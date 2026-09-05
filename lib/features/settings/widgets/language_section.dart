import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/features/settings/language_references_page.dart';
import 'settings_widgets.dart';

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final String language = LocaleController.instance.language;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(title: AppText.tr('menu_language')),
            SettingsCard(
              children: [
                SettingsTile(
                  title: AppText.tr('menu_english'),
                  selected: language == 'en',
                  onTap: () => LocaleController.instance.setLanguage('en'),
                ),
                SettingsTile(
                  title: AppText.tr('menu_french'),
                  selected: language == 'fr',
                  onTap: () => LocaleController.instance.setLanguage('fr'),
                ),
                SettingsTile(
                  title: AppText.tr('menu_malagasy'),
                  selected: language == 'mg',
                  onTap: () => LocaleController.instance.setLanguage('mg'),
                ),
              ],
            ),
            if (language == 'mg')
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 0.0),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12.0,
                      color: mutedTextColor(context),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Misy '),
                      TextSpan(
                        text: 'fiteny',
                        style: const TextStyle(
                          color: tanoAmber,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguageReferencesPage(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: ' na '),
                      TextSpan(
                        text: 'voambolana',
                        style: const TextStyle(
                          color: tanoAmber,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguageReferencesPage(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(
                        text: ' sasany notsongaina manokana noho izy ireo fohy kokoa no sady feno ara-kevitra.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
