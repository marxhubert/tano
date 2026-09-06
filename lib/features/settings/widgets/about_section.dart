import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/info.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/features/settings/about_page.dart';
import 'package:tano/features/settings/update_page.dart';
import 'package:tano/features/settings/feedback_page.dart';
import 'settings_widgets.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.viewModel});
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(title: AppText.tr('about')),
            SettingsCard(
              children: [
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
                SettingsTile(
                  title: AppText.tr('option_check_update'),
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UpdatePage()),
                    );
                  },
                ),
                SettingsTile(
                  title: AppText.tr('option_feedback'),
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackPage()),
                    );
                  },
                ),
                SettingsSwitchTile(
                  title: AppText.tr('option_bug_report'),
                  value: viewModel.bugReportEnabled,
                  onChanged: (val) => viewModel.setBugReportEnabled(val),
                ),
              ],
            ),
            SettingsFooter(
              children: [
                SettingsFooterText(text: AppText.tr('desc_bug_report')),
              ],
            ),
          ],
        );
      },
    );
  }
}
