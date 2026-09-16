import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

import 'package:tano/features/settings/widgets/settings_widgets.dart';
import 'package:tano/features/settings/licenses_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final SettingsViewModel _viewModel = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = primaryTextColor(context);

    final Widget tanoTitle = RichText(
      text: TextSpan(
        text: AppConfig.appName,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textColor,
          fontSize: 24.0,
          letterSpacing: -1.0,
        ),
        children: <TextSpan>[
          TextSpan(
            text: AppConfig.appNameSuffix,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: textColor,
              fontSize: 24.0,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: 'About',
      appBarTitleWidget: const TanoAppBarTitle(),
      titleWidget: Row(
        children: [
          const SizedBox(
            width: 40.0,
            height: 40.0,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: Icon(Symbols.bookmark, size: 24.0, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6.0),
          tanoTitle,
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final PackageInfo? info = _viewModel.packageInfo;
                return Text(
                  info == null
                      ? ''
                      : 'Version ${info.version} (${info.buildNumber})',
                  style: TextStyle(
                    color: mutedTextColor(context),
                    fontSize: 14.0,
                  ),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.tr('about_description'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16.0,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  AppText.tr('about_cta'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16.0,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 24.0),
          sliver: SliverToBoxAdapter(
            child: SettingsGroup(
              tiles: [
                SettingsTile(
                  title: AppText.tr('about_premium'),
                  selected: false,
                  onTap: () {
                    // TODO: Implement Premium
                  },
                  trailing: const Icon(
                    Symbols.star,
                    color: tanoAmber,
                    size: 20,
                  ),
                ),
                SettingsTile(
                  title: 'Buy Me a Coffee',
                  selected: false,
                  onTap: () =>
                      _launchUrl('https://www.buymeacoffee.com/marxhubert'),
                  trailing: const Icon(
                    Symbols.coffee,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                SettingsTile(
                  title: 'GitHub Sponsors',
                  selected: false,
                  onTap: () =>
                      _launchUrl('https://github.com/sponsors/shikamarx'),
                  trailing: const Icon(
                    Symbols.favorite,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                SettingsTile(
                  title: 'PayPal',
                  selected: false,
                  onTap: () => _launchUrl('https://paypal.me/marxhubert'),
                  trailing: const Icon(
                    Symbols.credit_card,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppText.tr('about_more'),
              style: TextStyle(color: textColor, fontSize: 16.0, height: 1.6),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return SettingsGroup(
                  tiles: [
                    SettingsSwitchTile(
                      title: AppText.tr('option_bug_report'),
                      value: _viewModel.bugReportEnabled,
                      onChanged: (val) => _viewModel.setBugReportEnabled(val),
                    ),
                    SettingsTile(
                      title: AppText.tr('licenses'),
                      selected: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LicensesPage(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            padding: const EdgeInsets.only(top: 90.0, bottom: 24.0),
            alignment: Alignment.bottomCenter,
            child: Text(
              '© 2026, Marx Hubert',
              style: TextStyle(color: mutedTextColor(context), fontSize: 12.0),
            ),
          ),
        ),
      ],
    );
  }
}
