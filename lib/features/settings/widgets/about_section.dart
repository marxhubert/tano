import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/features/settings/about_page.dart';
import 'settings_widgets.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.viewModel});
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return SettingsGroup(
          title: AppText.tr('about'),
          tiles: <Widget>[
            SettingsTile(
              title: AppText.tr('about'),
              selected: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),

            SettingsSwitchTile(
              title: AppText.tr('option_bug_report'),
              value: viewModel.bugReportEnabled,
              onChanged: (val) => viewModel.setBugReportEnabled(val),
            ),
            // Design sandbox for the future task and project cards.
            SettingsTile(
              title: 'Labo',
              selected: false,
              onTap: () => Navigator.of(context).pushNamed('/lab'),
            ),
          ],
          footer: <Widget>[
            SettingsFooterText(text: AppText.tr('desc_bug_report')),
          ],
        );
      },
    );
  }
}
