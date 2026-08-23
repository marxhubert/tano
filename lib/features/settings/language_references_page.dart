import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';

class LanguageReferencesPage extends StatelessWidget {
  const LanguageReferencesPage({super.key});

  String _buildUrl(String word) {
    final String normalized = word.toLowerCase().replaceAll('-', '');
    return 'https://malagasyword.org/bins/teny2/$normalized';
  }

  Future<void> _launchUrl(String word) async {
    final String url = _buildUrl(word);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MalagasyWordRef> refs =
        LanguageReferencesController.instance.references;

    return PageScaffold(
      title: AppText.tr('language_references'),
      headerTrailing: Text(
        'Teny ${refs.length} isa',
        style: TextStyle(
          color: mutedTextColor(context),
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
      ),
      actions: const [ThemeToggleButton()],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              "Natao ity hanazavana ireo teny sy fiteny nampiasaina ato amin'ity rindrankajy ity. Niezahana ho voambolana malagasy ofisialy, saingy misy fiteny mifanendrika bebe kokoa amin'ny angaly tiana havoitra. \n\nIreto izy ireo raha mahaliana anao ny heviny. Araho ny rohy ho fanampim-panazavana misimisy kokoa.",
              style: TextStyle(
                fontSize: 13.0,
                color: mutedTextColor(context),
                height: 1.5,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
          sliver: SliverList.separated(
            itemCount: refs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1.0,
              thickness: 0.5,
              color: primaryTextColor(context).withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final ref = refs[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: mutedTextColor(context),
                                fontSize: 13.0,
                                fontWeight: FontWeight.normal,
                              ),
                              children: [
                                TextSpan(text: "${index + 1}. "),
                                TextSpan(
                                  text: ref.word,
                                  style: TextStyle(
                                    color: primaryTextColor(context),
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (ref.hasWebsiteRef)
                          GestureDetector(
                            onTap: () => _launchUrl(ref.word),
                            child: const Icon(
                              Icons.open_in_new,
                              size: 14.0,
                              color: tanoAmber,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      ref.description,
                      style: TextStyle(
                        color: mutedTextColor(context),
                        fontSize: 13.0,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
