import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/services/update_service.dart';
import 'package:tano/features/onboarding/onboarding_page.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

import 'package:tano/features/settings/widgets/settings_widgets.dart';
import 'package:tano/features/settings/licenses_page.dart';
import 'package:tano/features/settings/privacy_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  final SettingsViewModel _viewModel = SettingsViewModel();
  final UpdateService _updates = UpdateService();

  bool _isCheckingUpdate = false;
  late final AnimationController _rotationController;

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

  /// The store is asked only when it is asked for, and a failure is never
  /// dressed up as an error: an offline app must not nag.
  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    _rotationController.repeat();

    final AppUpdate update = await _updates.check(force: true);

    if (!mounted) return;
    _rotationController
      ..stop()
      ..reset();
    setState(() => _isCheckingUpdate = false);

    if (update.isAvailable) {
      await _updates.apply(update);
      return;
    }

    await showAdaptiveNotice(
      context,
      update.status == UpdateStatus.upToDate
          ? AppText.tr('update_up_to_date')
          : AppText.tr('update_unavailable'),
    );
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // The app has a single red, with a variant for each theme.
    final Color red = isDark ? TanoStates.error.dark : TanoStates.error.light;

    final Widget tanoTitle = RichText(
      text: TextSpan(
        text: AppConfig.appName,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textColor,
          fontSize: TanoText.pageTitle,
          letterSpacing: -1.0,
        ),
        children: <TextSpan>[
          TextSpan(
            text: AppConfig.appNameSuffix,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: textColor,
              fontSize: TanoText.pageTitle,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: AppText.tr('about'),
      appBarTitleWidget: const TanoAppBarTitle(),
      titleWidget: Row(
        children: [
          SizedBox(
            width: 40.0,
            height: 40.0,
            child: CircleAvatar(
              // The mark inverts with the theme: a dark disc with a white
              // bookmark on the light screens, the other way round on the dark.
              backgroundColor: isDark ? Colors.white : Colors.black87,
              child: Icon(
                Symbols.bookmark,
                size: 24.0,
                color: isDark ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          tanoTitle,
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: sectionGap),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final PackageInfo? info = _viewModel.packageInfo;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        info == null
                            ? ''
                            : 'Version ${info.version} (${info.buildNumber})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedTextColor(context),
                          fontSize: TanoText.label,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _checkUpdate,
                      icon: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (BuildContext context, Widget? child) =>
                            Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: child,
                            ),
                        child: Icon(
                          Symbols.update,
                          size: 16.0,
                          color: _isCheckingUpdate ? tanoTeal : Colors.grey,
                        ),
                      ),
                      label: Text(
                        AppText.tr('option_update'),
                        style: TextStyle(
                          color: _isCheckingUpdate ? tanoTeal : Colors.grey,
                          fontSize: TanoText.label,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
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
                    fontSize: TanoText.body,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: appPaddingWide),
                Text(
                  AppText.tr('about_cta'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: TanoText.body,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(appPaddingMedium, 0.0, appPaddingMedium, sectionGap),
          sliver: SliverToBoxAdapter(
            child: SettingsGroup(
              // The paragraphs above already breathe; keep the gap tight.
              topSpacing: 12.0,
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
                    fill: 1.0,
                  ),
                ),
                // Only what this build configured: a fork that names no
                // support page shows no support page.
                if (AppConfig.coffeeUrl.isNotEmpty)
                  SettingsTile(
                    title: AppConfig.coffeeName,
                    selected: false,
                    onTap: () => _launchUrl(AppConfig.coffeeUrl),
                    trailing: Icon(
                      Symbols.coffee,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                      fill: 1.0,
                    ),
                  ),
                if (AppConfig.sponsorUrl.isNotEmpty)
                  SettingsTile(
                    title: AppConfig.sponsorName,
                    selected: false,
                    onTap: () => _launchUrl(AppConfig.sponsorUrl),
                    trailing: Icon(
                      Symbols.favorite,
                      color: red,
                      size: 20,
                      fill: 1.0,
                    ),
                  ),
                if (AppConfig.paypalUrl.isNotEmpty)
                  SettingsTile(
                    title: AppConfig.paypalName,
                    selected: false,
                    onTap: () => _launchUrl(AppConfig.paypalUrl),
                    // PayPal keeps its own blue, whatever the theme.
                    trailing: const Icon(
                      Symbols.credit_card,
                      color: Colors.blue,
                      size: 20,
                      fill: 1.0,
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
              style: TextStyle(color: textColor, fontSize: TanoText.body, height: 1.6),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(appPaddingMedium, 0.0, appPaddingMedium, 0.0),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return SettingsGroup(
                  topSpacing: 12.0,
                  tiles: [
                    SettingsTile(
                      title: AppText.tr('privacy'),
                      selected: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPage(),
                          ),
                        );
                      },
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
          padding: const EdgeInsets.fromLTRB(
            appPaddingMedium,
            0.0,
            appPaddingMedium,
            0.0,
          ),
          sliver: SliverToBoxAdapter(
            child: SettingsGroup(
              tiles: [
                SettingsTile(
                  title: AppText.tr('onboarding_replay'),
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext onboardingContext) =>
                            OnboardingPage(
                              onFinished: () =>
                                  Navigator.of(onboardingContext).pop(),
                            ),
                      ),
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
            padding: const EdgeInsets.only(top: 4 * sectionGap, bottom: sectionGap),
            alignment: Alignment.bottomCenter,
            child: Text(
              // A build that names no author shows the year alone.
              AppConfig.authorName.isEmpty
                  ? '© ${AppConfig.year}'
                  : '© ${AppConfig.year}, ${AppConfig.authorName}',
              style: TextStyle(color: mutedTextColor(context), fontSize: TanoText.tiny),
            ),
          ),
        ),
      ],
    );
  }
}
