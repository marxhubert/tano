import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';

/// TEMPORARY lab used to validate the card refactoring (lot 2) before it
/// reaches the real screens. Delete this page and its settings entry once the
/// new card is validated.
///
/// It renders the new [EntityCard] for both a folder and a note:
/// - 3 list cards: compact (no cover), normal (with cover), locked
/// - 3 grid cards, 3 per line (square): without cover, with cover, locked
/// for 12 cards in total.
class CardLabPage extends StatefulWidget {
  const CardLabPage({super.key});

  @override
  State<CardLabPage> createState() => _CardLabPageState();
}

class _CardLabPageState extends State<CardLabPage> {
  static const String _coverFileName = 'tano_lab_cover.png';

  /// Stored name of the generated cover, or null until it is ready.
  String? _cover;

  @override
  void initState() {
    super.initState();
    _prepareCover();
  }

  /// Generates a real cover image and stores it, so the "with cover" cards
  /// exercise the whole cover path (materialize, image.file, dim layer).
  /// Falls back to the file name alone, which shows the placeholder.
  Future<void> _prepareCover() async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File(p.join(dir.path, _coverFileName));
      if (!file.existsSync()) {
        await file.writeAsBytes(await _renderCover());
      }
      final String name =
          await AttachmentsStore().import(file.path, _coverFileName);
      if (mounted) setState(() => _cover = name);
    } catch (error) {
      debugPrint('Card lab: cover unavailable ($error)');
      if (mounted) setState(() => _cover = _coverFileName);
    }
  }

  Future<Uint8List> _renderCover() async {
    const double width = 480.0;
    const double height = 320.0;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0.0, 0.0, width, height),
    );
    final Paint background = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(width, height),
        <Color>[tanoTeal, tanoAmber],
      );
    canvas.drawRect(
      const Rect.fromLTWH(0.0, 0.0, width, height),
      background,
    );
    canvas.drawCircle(
      const Offset(width * 0.72, height * 0.34),
      62.0,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    final ui.Image image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Labo cartes',
      // Theme toggle hard right, so light/dark can be judged on the spot.
      actions: const <Widget>[ThemeToggleButton()],
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            appPaddingLarge,
            0.0,
            appPaddingLarge,
            60.0,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              ..._folderBlocks(),
              ..._noteBlocks(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _folderBlocks() {
    final Folder base = Folder(
      id: 'lab-folder',
      name: 'Dossier des projets et documents administratifs',
      date: '2026-01-01 10:00:00.000',
      category: 'azur',
    );
    return <Widget>[
      _section('Dossier'),
      _label('Liste — compact (sans couverture)'),
      _sized(EntityCardHeight.compact, _folderCard(base, null, isList: true)),
      const SizedBox(height: 12.0),
      _label('Liste — normal (avec couverture)'),
      _sized(EntityCardHeight.normal, _folderCard(base, _cover, isList: true)),
      const SizedBox(height: 12.0),
      _label('Liste — verrouillé (compact, avec pointillés)'),
      _sized(
        EntityCardHeight.compact,
        _folderCard(base, null, isList: true, locked: true),
      ),
      const SizedBox(height: 24.0),
      _label('Grille — square, 3 par ligne : sans couverture, avec '
          'couverture, verrouillé'),
      _grid(<Widget>[
        _folderCard(base, null, isList: false),
        _folderCard(base, _cover, isList: false),
        _folderCard(base, _cover, isList: false, locked: true),
      ]),
      const SizedBox(height: 40.0),
    ];
  }

  List<Widget> _noteBlocks() {
    final Note base = Note(
      id: 'lab-note',
      title: 'Compte rendu de la reunion du comite de suivi du projet',
      // About a hundred words, to judge a long excerpt on the cards.
      content: "Voici un contenu de note volontairement long pour visualiser le "
          "comportement de la carte quand le texte déborde. Plusieurs phrases "
          "se suivent afin de remplir l'espace disponible et de montrer comment "
          "le contenu se réduit, se coupe ou laisse apparaître une ellipse "
          "selon la place restante. L'objectif est de vérifier la lisibilité, "
          "la hauteur des lignes et l'alignement avec la date, le titre et la "
          "metadata. Ce texte répétitif simule une vraie note prise rapidement, "
          "avec des idées qui s'enchaînent, des précisions et des exemples "
          "concrets, comme on le ferait dans l'application au quotidien. "
          "Ajuste ensuite les valeurs pour comparer les rendus.",
      date: '2026-01-01 10:00:00.000',
      category: 'menthe',
      attachments: <String>['piece-jointe.pdf'],
    );
    return <Widget>[
      _section('Note'),
      _label('Liste — compact (sans couverture)'),
      _sized(EntityCardHeight.compact, _noteCard(base, null, isList: true)),
      const SizedBox(height: 12.0),
      _label('Liste — normal (avec couverture)'),
      _sized(EntityCardHeight.normal, _noteCard(base, _cover, isList: true)),
      const SizedBox(height: 12.0),
      _label('Liste — verrouillé (compact, avec pointillés)'),
      _sized(
        EntityCardHeight.compact,
        _noteCard(base, null, isList: true, locked: true),
      ),
      const SizedBox(height: 24.0),
      _label('Grille — square, 3 par ligne : sans couverture, avec '
          'couverture, verrouillé'),
      _grid(<Widget>[
        _noteCard(base, null, isList: false),
        _noteCard(base, _cover, isList: false),
        _noteCard(base, _cover, isList: false, locked: true),
      ]),
    ];
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _label(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.0,
          color: mutedTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Forces one of the three allowed card heights.
  Widget _sized(EntityCardHeight height, Widget card) {
    return SizedBox(height: height.value, child: card);
  }

  /// The exact grid configuration used by the real screens (three columns,
  /// 8px gaps) with a fixed [EntityCardHeight.square] height, so a card is
  /// sized as in the app even when fewer than three are shown.
  Widget _grid(List<Widget> children) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount(context),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        mainAxisExtent: EntityCardHeight.square.value,
      ),
      itemBuilder: (BuildContext context, int index) => children[index],
    );
  }

  Widget _folderCard(
    Folder folder,
    String? cover, {
    required bool isList,
    bool locked = false,
  }) {
    final Folder shown = folder.copyWith(coverImage: cover);
    return EntityCard(
      kind: EntityKind.folder,
      category: shown.category,
      title: shown.name,
      subtitle: 'x3',
      subtitleIcon: Icons.description_outlined,
      coverImage: cover,
      isLocked: locked,
      isListLayout: isList,
      isSelectable: !locked,
      onTap: () {},
      builder: (BuildContext context, Color textColor, bool hasCover) => isList
          ? _folderListBody(context, shown, 3, textColor, hasCover)
          : _folderGridBody(context, shown, 3, textColor, hasCover),
    );
  }

  Widget _noteCard(
    Note note,
    String? cover, {
    required bool isList,
    bool locked = false,
  }) {
    final Note shown = note.copyWith(coverImage: cover, isLocked: locked);
    return EntityCard(
      kind: EntityKind.note,
      category: shown.category,
      title: shown.title,
      subtitle: formatNoteDate(shown.date),
      coverImage: cover,
      isLocked: locked,
      isListLayout: isList,
      onTap: () {},
      builder: (BuildContext context, Color textColor, bool hasCover) => isList
          ? _noteListBody(shown, textColor, hasCover)
          : _noteGridBody(shown, textColor, hasCover),
    );
  }

  Widget _folderGridBody(
    BuildContext context,
    Folder folder,
    int noteCount,
    Color textColor,
    bool hasCover,
  ) {
    return Padding(
      // Grid padding 8, gap under a cover 4, metadata 4 from the bottom.
      padding: EdgeInsets.fromLTRB(8.0, hasCover ? 4.0 : 8.0, 8.0, 4.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              folder.name,
              maxLines: hasCover ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(textColor),
            ),
            const Spacer(),
            _folderMeta(textColor, noteCount),
          ],
        ),
      ),
    );
  }

  Widget _folderListBody(
    BuildContext context,
    Folder folder,
    int noteCount,
    Color textColor,
    bool hasCover,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      // Like the locked list template: the name and its metadata are one
      // block, centred vertically and left aligned.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            folder.name,
            // Folder list and locked list are the exception: two lines even
            // with a cover.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(textColor),
          ),
          _folderMeta(textColor, noteCount),
        ],
      ),
    );
  }

  Widget _folderMeta(Color textColor, int noteCount) {
    final Color color = textColor.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.description_outlined, size: _metaIconSize, color: color),
          Text('x$noteCount',
              style: TextStyle(fontSize: _metaSize, color: color)),
        ],
      ),
    );
  }

  /// Note grid body. The excerpt takes the space left by the date and the
  /// title, and shrinks when there is less of it (no excerpt with a cover,
  /// where the lower half holds the title only).
  Widget _noteGridBody(Note note, Color textColor, bool hasCover) {
    return Container(
      // Grid padding 8; gap under a cover 4; metadata 4 from the bottom.
      padding: EdgeInsets.fromLTRB(8.0, hasCover ? 4.0 : 8.0, 8.0, 4.0),
      child: Column(
        // Metadata always left-aligned, body top-aligned.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: <Widget>[
                Text(
                  formatNoteDate(note.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _dateStyle(textColor),
                ),
                Text(
                  note.title,
                  maxLines: hasCover ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(textColor),
                ),
                if (!hasCover)
                  Expanded(child: _noteExcerpt(note, textColor)),
              ],
            ),
          ),
          NoteCounts(
            content: note.content,
            color: textColor.withValues(alpha: 0.6),
            attachmentCount: note.attachments.length,
          ),
        ],
      ),
    );
  }

  /// Note list body. The excerpt fills the remaining height and clips when the
  /// two-line title leaves it little room.
  Widget _noteListBody(Note note, Color textColor, bool hasCover) {
    return Padding(
      // List padding 12, but the metadata sits 4 from the bottom.
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  note.title,
                  maxLines: hasCover ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(textColor),
                ),
              ),
              const SizedBox(width: 9.0),
              Text(
                formatNoteDate(note.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _dateStyle(textColor),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Expanded(child: _noteExcerpt(note, textColor)),
          NoteCounts(
            content: note.content,
            color: textColor.withValues(alpha: 0.6),
            attachmentCount: note.attachments.length,
          ),
        ],
      ),
    );
  }

  /// Excerpt that fills the remaining height. Its line count is computed from
  /// that height so the text always ends on a full line with an ellipsis,
  /// instead of being clipped in the middle of one.
  Widget _noteExcerpt(Note note, Color textColor) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double lineHeight = _contentSize * 1.4;
        final int fit = (constraints.maxHeight / lineHeight).floor();
        final int maxLines = fit < 1 ? 1 : fit;
        return Align(
          alignment: Alignment.topLeft,
          child: RichText(
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            text: LinkTextEditingController.buildMarkdownTextSpan(
              note.content,
              TextStyle(
                fontSize: _contentSize,
                color: textColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
              tanoAmber,
              const <String>{},
            ),
          ),
        );
      },
    );
  }

  // Sizes all taken from the note grid card, the reference for every card.
  static const double _titleSize = 11.0;
  static const double _dateSize = 9.0;
  static const double _contentSize = 10.0;
  static const double _metaSize = 9.0;
  static const double _metaIconSize = 11.0;

  TextStyle _titleStyle(Color textColor) => TextStyle(
        fontSize: _titleSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  TextStyle _dateStyle(Color textColor) =>
      TextStyle(fontSize: _dateSize, color: textColor.withValues(alpha: 0.6));
}
