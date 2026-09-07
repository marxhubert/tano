import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
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

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  bool _isCheckingUpdate = false;
  late AnimationController _rotationController;
  final SettingsViewModel _viewModel = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
    });
    _rotationController.repeat();
    
    // TODO: Implement real update check later
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      _rotationController.stop();
      setState(() {
        _isCheckingUpdate = false;
      });
    }
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

    final Widget appBarTanoTitle = RichText(
      text: TextSpan(
        text: AppConfig.appName,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textColor,
          fontSize: 17.0,
          letterSpacing: -0.41,
        ),
        children: <TextSpan>[
          TextSpan(
            text: AppConfig.appNameSuffix,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 17.0,
              letterSpacing: -0.41,
            ),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: 'About',
      appBarTitleWidget: appBarTanoTitle,
      titleWidget: Row(
        children: [
          const SizedBox(
            width: 40.0,
            height: 40.0,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: Icon(Icons.bookmark_border, size: 24.0, color: Colors.white),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Version 1.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                  ),
                ),
                TextButton.icon(
                  onPressed: _checkUpdate,
                  icon: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.update,
                      size: 16.0,
                      color: _isCheckingUpdate ? tanoTeal : Colors.grey,
                    ),
                  ),
                  label: Text(
                    AppText.tr('option_check_update'),
                    style: TextStyle(
                      color: _isCheckingUpdate ? tanoTeal : Colors.grey,
                      fontSize: 14.0,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
          sliver: SliverToBoxAdapter(
            child: SettingsCard(
              children: [
                SettingsTile(
                  title: AppText.tr('about_premium'),
                  selected: false,
                  onTap: () {
                    // TODO: Implement Premium
                  },
                  trailing: const Icon(Icons.star_outline, color: tanoAmber, size: 20),
                ),
                SettingsTile(
                  title: 'Buy Me a Coffee',
                  selected: false,
                  onTap: () => _launchUrl('https://www.buymeacoffee.com/marxhubert'),
                  trailing: const Icon(Icons.coffee_outlined, color: Colors.grey, size: 20),
                ),
                SettingsTile(
                  title: 'GitHub Sponsors',
                  selected: false,
                  onTap: () => _launchUrl('https://github.com/sponsors/shikamarx'),
                  trailing: const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                ),
                SettingsTile(
                  title: 'PayPal',
                  selected: false,
                  onTap: () => _launchUrl('https://paypal.me/marxhubert'),
                  trailing: const Icon(Icons.payment, color: Colors.grey, size: 20),
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
              style: TextStyle(
                color: textColor,
                fontSize: 16.0,
                height: 1.6,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return SettingsCard(
                  children: [
                    SettingsTile(
                      title: AppText.tr('option_feedback'),
                      selected: false,
                      onTap: () => _viewModel.sendFeedback(),
                    ),
                    SettingsSwitchTile(
                      title: AppText.tr('option_bug_report'),
                      value: _viewModel.bugReportEnabled,
                      onChanged: (val) => _viewModel.setBugReportEnabled(val),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: SettingsCard(
              children: [
                SettingsTile(
                  title: AppText.tr('licenses'),
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LicensesPage()),
                    );
                  },
                ),
              ],
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
              style: TextStyle(
                color: mutedTextColor(context),
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
