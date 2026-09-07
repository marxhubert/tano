import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';

class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  String _licenseText = '';
  final String _currentLang = LocaleController.instance.language;
  bool _showingOriginal = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    setState(() => _isLoading = true);
    final langToLoad = _showingOriginal ? 'en' : _currentLang;
    try {
      final text = await rootBundle.loadString('assets/licenses/$langToLoad.txt');
      if (mounted) {
        setState(() {
          _licenseText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _licenseText = 'Error loading license content.';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleOriginal() {
    setState(() {
      _showingOriginal = !_showingOriginal;
    });
    _loadLicense();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final String displayLang = _showingOriginal ? 'en' : _currentLang;
    final String langName = AppText.tr('lang_$displayLang');

    return PageScaffold(
      title: AppText.tr('licenses'),
      actions: const [
        ThemeToggleButton(),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      langName,
                      style: TextStyle(
                        color: mutedTextColor(context),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '2026',
                      style: TextStyle(
                        color: mutedTextColor(context),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_currentLang != 'en' && !_showingOriginal) ...[
                  const SizedBox(height: 16.0),
                  Text(
                    AppText.tr('license_disclaimer'),
                    style: TextStyle(
                      fontSize: 13.0,
                      color: mutedTextColor(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: _toggleOriginal,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: tanoAmber,
                    ),
                    child: Text(
                      AppText.tr('license_view_original'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ] else if (_showingOriginal && _currentLang != 'en') ...[
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: _toggleOriginal,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: tanoAmber,
                    ),
                    child: Text(
                      isIOS ? 'Back to translation' : 'BACK TO TRANSLATION',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
          sliver: SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : Text(
                    _licenseText,
                    style: TextStyle(
                      color: primaryTextColor(context),
                      fontSize: 16.0,
                      height: 1.6,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
