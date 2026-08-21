import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/info.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _setSorting(String sortBy) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortBy', sortBy);
    if (mounted) setState(() {});
  }

  Future<String> _getSorting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('sortBy') ?? 'date';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        return PageScaffold(
          title: AppText.tr('settings'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SettingsSection(title: AppText.tr('menu_language')),
                  _SettingsTile(
                    title: AppText.tr('menu_english'),
                    selected: LocaleController.instance.language == 'en',
                    onTap: () => LocaleController.instance.setLanguage('en'),
                  ),
                  _SettingsTile(
                    title: AppText.tr('menu_french'),
                    selected: LocaleController.instance.language == 'fr',
                    onTap: () => LocaleController.instance.setLanguage('fr'),
                  ),
                  const _SettingsDivider(),
                  _SettingsSection(title: AppText.tr('menu_theme')),
                  _SettingsTile(
                    title: AppText.tr('theme_light'),
                    selected: ThemeController.instance.themeMode == ThemeMode.light,
                    onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                  ),
                  _SettingsTile(
                    title: AppText.tr('theme_dark'),
                    selected: ThemeController.instance.themeMode == ThemeMode.dark,
                    onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
                  ),
                  _SettingsTile(
                    title: AppText.tr('theme_system'),
                    selected: ThemeController.instance.themeMode == ThemeMode.system,
                    onTap: () => ThemeController.instance.setThemeMode(ThemeMode.system),
                  ),
                  const _SettingsDivider(),
                  _SettingsSection(title: AppText.tr('menu_sorting')),
                  FutureBuilder<String>(
                    future: _getSorting(),
                    builder: (context, snapshot) {
                      final currentSort = snapshot.data ?? 'date';
                      return Column(
                        children: [
                          _SettingsTile(
                            title: AppText.tr('menu_date'),
                            selected: currentSort == 'date',
                            onTap: () => _setSorting('date'),
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_title'),
                            selected: currentSort == 'alpha',
                            onTap: () => _setSorting('alpha'),
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_favorites'),
                            selected: currentSort == 'important',
                            onTap: () => _setSorting('important'),
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_category'),
                            selected: currentSort == 'category',
                            onTap: () => _setSorting('category'),
                          ),
                        ],
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsSection(title: AppText.tr('about')),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                    title: Text(
                      AppText.tr('about'),
                      style: TextStyle(
                        color: primaryTextColor(context),
                        fontSize: 14.0,
                      ),
                    ),
                    trailing: const Icon(Icons.info_outline, size: 20.0),
                    onTap: () {
                      if (_packageInfo != null) {
                        showDialog(
                          context: context,
                          builder: (context) => aboutInfo(
                            context: context,
                            packageInfo: _packageInfo!,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40.0),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6.0, 16.0, 6.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: tanoTeal.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11.0,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
      dense: true,
      title: Text(
        title,
        style: TextStyle(
          color: selected ? tanoTeal : primaryTextColor(context),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14.0,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: tanoTeal, size: 20.0)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 32.0,
      thickness: 0.5,
      color: primaryTextColor(context).withValues(alpha: 0.1),
      indent: 6.0,
      endIndent: 6.0,
    );
  }
}
