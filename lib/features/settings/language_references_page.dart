import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';

class LanguageReferencesPage extends StatelessWidget {
  const LanguageReferencesPage({super.key});

  static const Map<String, String?> _references = {
    'Fandraisana': 'https://malagasyword.org/bins/teny/fandraisana',
    'Naoty': 'https://malagasyword.org/bins/teny/naoty',
    'Karohy': 'https://malagasyword.org/bins/teny/karohy',
    'Voalamina': 'https://malagasyword.org/bins/teny/voalamina',
    'Voafantina': 'https://malagasyword.org/bins/teny/voafantina',
    'Fafao': 'https://malagasyword.org/bins/teny/fafao',
    'Avereno': 'https://malagasyword.org/bins/teny/avereno',
    'Tehirizo': 'https://malagasyword.org/bins/teny/tehirizo',
    'Lohateny': 'https://malagasyword.org/bins/teny/lohateny',
    'Votoatiny': 'https://malagasyword.org/bins/teny/votoatiny',
    'Zava-dehibe': 'https://malagasyword.org/bins/teny/zavadehibe',
    'Fikirana': 'https://malagasyword.org/bins/teny/fikirana',
    'Loko': 'https://malagasyword.org/bins/teny/loko',
    'Lisitra': 'https://malagasyword.org/bins/teny/lisitra',
    'Rakitra': 'https://malagasyword.org/bins/teny/rakitra',
    'Mpiara-miasa': 'https://malagasyword.org/bins/teny/mpiaramiasa',
    'Hizara': 'https://malagasyword.org/bins/teny/hizara',
    'Hahidy': 'https://malagasyword.org/bins/teny/hahidy',
    'Endrika': 'https://malagasyword.org/bins/teny/endrika',
    'Filaminana': 'https://malagasyword.org/bins/teny/filaminana',
    'Fiteny': 'https://malagasyword.org/bins/teny/fiteny',
    'Voambolana': 'https://malagasyword.org/bins/teny/voambolana',
  };

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> keys = _references.keys.toList()..sort();

    return PageScaffold(
      title: AppText.tr('language_references'),
      actions: const [ThemeToggleButton()],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 0.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              "Natao ity hanazavana ireo teny sy fiteny nampiasaina ato amin'ity rindrankajy ity. Niezahana ho voambolana malagasy ofisialy, saingy misy fiteny mifanendrika bebe kokoa amin'ny angaly tiana havoitra. Ireto izy ireo raha mahaliana anao ny heviny. Araho ny rohy ho fanampim-panazavana misimisy kokoa.",
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
            itemCount: keys.length,
            separatorBuilder: (context, index) => Divider(
              height: 1.0,
              thickness: 0.5,
              color: primaryTextColor(context).withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final String word = keys[index];
              final String? url = _references[word];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        word,
                        style: TextStyle(
                          color: primaryTextColor(context),
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    if (url != null)
                      GestureDetector(
                        onTap: () => _launchUrl(url),
                        child: const Icon(
                          Icons.open_in_new,
                          size: 14.0,
                          color: tanoAmber,
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
