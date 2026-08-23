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
                  // --- THEME ---
                  _SettingsSection(title: AppText.tr('menu_theme')),
                  _SettingsCard(
                    children: [
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
                    ],
                  ),

                  // --- SORTING ---
                  _SettingsSection(title: AppText.tr('menu_sorting')),
                  FutureBuilder<String>(
                    future: _getSorting(),
                    builder: (context, snapshot) {
                      final currentSort = snapshot.data ?? 'date';
                      return _SettingsCard(
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

                  // --- LANGUAGE ---
                  _SettingsSection(title: AppText.tr('menu_language')),
                  _SettingsCard(
                    children: [
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
                    ],
                  ),

                  // --- ABOUT ---
                  _SettingsSection(title: AppText.tr('about')),
                  _SettingsCard(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('about'),
                          style: TextStyle(
                            color: primaryTextColor(context),
                            fontSize: 14.0,
                          ),
                        ),
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
                    ],
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
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 2.0),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1.0,
            thickness: 0.5,
            indent: 16.0, // Aligned with the text
            endIndent: 0.0, // Goes all the way to the right
            color: primaryTextColor(context).withValues(alpha: 0.08),
          ),
        );
      }
    }

    return Card(
      elevation: 0.0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(children: dividedChildren),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
