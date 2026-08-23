import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';

class LanguageReferencesPage extends StatelessWidget {
  const LanguageReferencesPage({super.key});

  static const List<String> _words = [
    'Fandraisana',
    'Naoty',
    'Karohy',
    'Voalamina',
    'Voafantina',
    'Fafao',
    'Avereno',
    'Tehirizo',
    'Lohateny',
    'Votoatiny',
    'Zava-dehibe',
    'Fikirana',
    'Loko',
    'Lisitra',
    'Rakitra',
    'Mpiara-miasa',
    'Hizara',
    'Hahidy',
    'Endrika',
    'Filaminana',
    'Fiteny',
    'Voambolana',
  ];

  String _buildUrl(String word) {
    // Normalization for the URL: lowercase and remove special characters like '-'
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
    final List<String> sortedWords = List.from(_words)..sort();

    return PageScaffold(
      title: AppText.tr('language_references'),
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
            itemCount: sortedWords.length,
            separatorBuilder: (context, index) => Divider(
              height: 1.0,
              thickness: 0.5,
              color: primaryTextColor(context).withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final String word = sortedWords[index];

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
                    GestureDetector(
                      onTap: () => _launchUrl(word),
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
