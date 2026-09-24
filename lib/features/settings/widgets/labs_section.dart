import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/services/crash_reports.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'settings_widgets.dart';

/// The Labs: the developer surface, kept as the last settings section.
///
/// [AppConfig.showsLabs] hides the whole section outside debug and development
/// builds, so a release build never reaches a lab. It gathers the tools that
/// only make sense to a developer — the fixtures reset used to live at the
/// bottom of the reset page — and the labs we add over time.
class LabsSection extends StatelessWidget {
  const LabsSection({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.showsLabs) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return SettingsGroup(
          title: AppText.tr('labs'),
          tiles: <Widget>[
            SettingsTile(
              title: AppText.tr('labs_sentry_test'),
              selected: false,
              trailing: Icon(
                Symbols.bug_report,
                size: 20.0,
                color: mutedTextColor(context),
              ),
              onTap: () => _sendTestError(context),
            ),
            SettingsTile(
              title: AppText.tr('developer_reset'),
              selected: false,
              textColor: TanoStates.error.dark,
              fontWeight: FontWeight.bold,
              onTap: viewModel.isResetting
                  ? () {}
                  : () => _developerReset(context),
            ),
          ],
          footer: <Widget>[SettingsFooterText(text: AppText.tr('labs_hint'))],
        );
      },
    );
  }

  /// Reports one synthetic error and says whether it went out: the path is only
  /// live once the user turned crash reports on.
  Future<void> _sendTestError(BuildContext context) async {
    final bool sent = await CrashReports.sendTestError();
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppText.tr(sent ? 'labs_sentry_sent' : 'labs_sentry_unavailable'),
        ),
      ),
    );
  }

  Future<void> _developerReset(BuildContext context) async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('developer_reset'),
      action: AppText.tr('reset'),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await viewModel.developerReset();
    } catch (_) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppText.tr('developer_reset')),
          content: Text(AppText.tr('developer_reset_failed')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.tr('ok')),
            ),
          ],
        ),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}
