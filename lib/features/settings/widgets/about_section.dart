import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/info.dart';
import 'package:tano/features/settings/settings_view_model.dart';
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
                    if (viewModel.packageInfo != null) {
                      showDialog(
                        context: context,
                        builder: (context) => aboutInfo(
                          context: context,
                          packageInfo: viewModel.packageInfo!,
                        ),
                      );
                    }
                  },
                ),
                SettingsTile(
                  title: AppText.tr('option_check_update'),
                  selected: false,
                  onTap: () => viewModel.checkForUpdates(),
                ),
                SettingsTile(
                  title: AppText.tr('option_feedback'),
                  selected: false,
                  onTap: () => viewModel.sendFeedback(),
                ),
                SettingsSwitchTile(
                  title: AppText.tr('option_bug_report'),
                  value: viewModel.bugReportEnabled,
                  onChanged: (val) => viewModel.setBugReportEnabled(val),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 0.0),
              child: Text(
                AppText.tr('desc_bug_report'),
                style: TextStyle(
                  fontSize: 12.0,
                  color: mutedTextColor(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
