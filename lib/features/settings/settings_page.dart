import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/info.dart';
import 'package:tano/features/settings/language_references_page.dart';
import 'package:tano/features/settings/settings_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsViewModel _viewModel = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel,
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        final ThemeMode currentMode = ThemeController.instance.themeMode;
        final bool isAutomatic = currentMode == ThemeMode.system;

        return PageScaffold(
          title: AppText.tr('settings'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: appPaddingMedium),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- APPEARANCE (THEME) ---
                  _SettingsSection(title: AppText.tr('menu_theme')),
                  _SettingsCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ThemePreview(
                              title: AppText.tr('theme_light'),
                              isDark: false,
                              isSelected: !isAutomatic && currentMode == ThemeMode.light,
                              onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                            ),
                            _ThemePreview(
                              title: AppText.tr('theme_dark'),
                              isDark: true,
                              isSelected: !isAutomatic && currentMode == ThemeMode.dark,
                              onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSwitchTile(
                        title: AppText.tr('theme_automatic'),
                        value: isAutomatic,
                        onChanged: (val) {
                          ThemeController.instance.setThemeMode(
                            val ? ThemeMode.system : (Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light),
                          );
                        },
                      ),
                    ],
                  ),

                  // --- SORTING ---
                  _SettingsSection(title: AppText.tr('menu_sorting')),
                  FutureBuilder<Map<String, dynamic>>(
                    future: Future.wait([
                      _viewModel.getSorting(),
                      _viewModel.getSortAscending(),
                    ]).then((res) => {'sortBy': res[0], 'ascending': res[1]}),
                    builder: (context, snapshot) {
                      final currentSort = snapshot.data?['sortBy'] ?? 'date';
                      final currentAsc = snapshot.data?['ascending'] ?? true;

                      return _SettingsCard(
                        children: [
                          _SettingsTile(
                            title: AppText.tr('menu_title'),
                            selected: currentSort == 'alpha',
                            onTap: () async {
                              await _viewModel.setSorting('alpha');
                              setState(() {});
                            },
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_date'),
                            selected: currentSort == 'date',
                            onTap: () async {
                              await _viewModel.setSorting('date');
                              setState(() {});
                            },
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_favorites'),
                            selected: currentSort == 'important',
                            onTap: () async {
                              await _viewModel.setSorting('important');
                              setState(() {});
                            },
                          ),
                          _SettingsTile(
                            title: AppText.tr('menu_theme_sort'),
                            selected: currentSort == 'theme' || currentSort == 'category',
                            onTap: () async {
                              await _viewModel.setSorting('theme');
                              setState(() {});
                            },
                          ),
                          _SettingsSwitchTile(
                            title: AppText.tr('menu_descending'),
                            value: !currentAsc,
                            onChanged: (val) async {
                              await _viewModel.setSortAscending(!val);
                              setState(() {});
                            },
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
                      _SettingsTile(
                        title: AppText.tr('menu_malagasy'),
                        selected: LocaleController.instance.language == 'mg',
                        onTap: () => LocaleController.instance.setLanguage('mg'),
                      ),
                    ],
                  ),
                  if (LocaleController.instance.language == 'mg')
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
                                text: ' sasany notsongaina manokana noho izy ireo fohy kokoa no sady feno ara-kevitra.'),
                          ],
                        ),
                      ),
                    ),

                  // --- ABOUT ---
                  _SettingsSection(title: AppText.tr('about')),
                  _SettingsCard(
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4.0),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('about'),
                          style: TextStyle(color: primaryTextColor(context), fontSize: 14.0),
                        ),
                        onTap: () {
                          if (_viewModel.packageInfo != null) {
                            showDialog(
                              context: context,
                              builder: (context) => aboutInfo(
                                context: context,
                                packageInfo: _viewModel.packageInfo!,
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4.0),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('option_check_update'),
                          style: TextStyle(color: primaryTextColor(context), fontSize: 14.0),
                        ),
                        onTap: () {}, // TODO: Implement check for update
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4.0),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('option_feedback'),
                          style: TextStyle(color: primaryTextColor(context), fontSize: 14.0),
                        ),
                        onTap: () {}, // TODO: Implement feedback
                      ),
                      _SettingsSwitchTile(
                        title: AppText.tr('option_bug_report'),
                        value: _viewModel.bugReportEnabled,
                        onChanged: (val) => _viewModel.setBugReportEnabled(val),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 0.0),
                    child: Text(
                      AppText.tr('desc_bug_report'),
                      style: TextStyle(fontSize: 12.0, color: mutedTextColor(context), height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // --- DATA MANAGEMENT ---
                  _SettingsCard(
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4.0),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('option_recycle_bin'),
                          style: TextStyle(color: primaryTextColor(context), fontSize: 14.0),
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed('/trash');
                        },
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4.0),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          AppText.tr('option_reset_data'),
                          style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {}, // TODO: Implement data reset
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.tr('desc_recycle_bin'),
                          style: TextStyle(fontSize: 12.0, color: mutedTextColor(context), height: 1.4),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          AppText.tr('desc_reset_data'),
                          style: TextStyle(fontSize: 12.0, color: mutedTextColor(context), height: 1.4),
                        ),
                      ],
                    ),
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
            indent: 16.0,
            endIndent: 0.0,
            color: primaryTextColor(context).withValues(alpha: 0.08),
          ),
        );
      }
    }

    return Card(
      elevation: 0.0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(children: dividedChildren),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.title,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color screenBg =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    // 9 Colors for the mock grid (Light/Dark pairs from TanoPastels)
    final List<Color> mockColors = isDark
        ? [
            const Color(0xFF004D40),
            const Color(0xFF827717),
            const Color(0xFFBF360C),
            const Color(0xFF4A148C),
            const Color(0xFF880E4F),
            const Color(0xFF01579B),
            const Color(0xFF3E2723),
            const Color(0xFF1B5E20),
            const Color(0xFFAD1457),
          ]
        : [
            const Color(0xFFE0F2F1),
            const Color(0xFFFFF9C4),
            const Color(0xFFFFE0B2),
            const Color(0xFFF3E5F5),
            const Color(0xFFFFEBEE),
            const Color(0xFFE1F5FE),
            const Color(0xFFF5F5DC),
            const Color(0xFFF1F8E9),
            const Color(0xFFFCE4EC),
          ];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              color: screenBg,
              borderRadius: BorderRadius.circular(isSelected ? 13.0 : 12.0),
              border: Border.all(
                color:
                    isSelected ? tanoAmber : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: tanoTeal,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(11.0)),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 16,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                Positioned.fill(
                  top: 20,
                  child: Padding(
                    padding: isSelected
                        ? const EdgeInsets.all(3.0)
                        : const EdgeInsets.all(4.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: mockColors
                          .map((color) => _MockNoteCard(color: color))
                          .toList(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: tanoTeal, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
                fontSize: 12.0,
                color: primaryTextColor(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
          const SizedBox(height: 6),
          Icon(
            isSelected ? Icons.check_circle : Icons.panorama_fish_eye,
            color: isSelected ? tanoAmber : Colors.grey.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _MockNoteCard extends StatelessWidget {
  const _MockNoteCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 1,
              offset: const Offset(0, 1)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(
      {required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -4.0),
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
          ? const Icon(Icons.check_circle, color: tanoTeal, size: 16.0)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile(
      {required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -4.0),
      contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
      dense: true,
      title: Text(title,
          style: TextStyle(color: primaryTextColor(context), fontSize: 14.0)),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch.adaptive(
            value: value, onChanged: onChanged, activeColor: tanoTeal),
      ),
    );
  }
}
