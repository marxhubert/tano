import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tano/shared/config/l10n.dart';

class MalagasyWordRef {
  final String key;
  final String word;
  final String description;
  final bool hasWebsiteRef;
  final bool shouldDisplay;

  MalagasyWordRef({
    required this.key,
    required this.word,
    required this.description,
    required this.hasWebsiteRef,
    required this.shouldDisplay,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'word': word,
        'description': description,
        'hasWebsiteRef': hasWebsiteRef,
        'shouldDisplay': shouldDisplay,
      };

  factory MalagasyWordRef.fromJson(Map<String, dynamic> json) => MalagasyWordRef(
        key: json['key'],
        word: json['word'],
        description: json['description'],
        hasWebsiteRef: json['hasWebsiteRef'],
        shouldDisplay: json['shouldDisplay'],
      );
}

class LanguageReferencesController {
  LanguageReferencesController._();
  static final LanguageReferencesController instance =
      LanguageReferencesController._();

  static const String _localFileName = 'malagasy_refs_runtime.json';
  List<MalagasyWordRef> _references = [];

  List<MalagasyWordRef> get references => _references;

  Future<void> init() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File localFile = File('${directory.path}/$_localFileName');

    // If local file exists, we load it. Otherwise, we generate it from asset.
    if (await localFile.exists()) {
      final String content = await localFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _references = jsonList.map((j) => MalagasyWordRef.fromJson(j)).toList();
    } else {
      await _generateInitialConfig(localFile);
    }
  }

  Future<void> _generateInitialConfig(File localFile) async {
    // 1. Load the dev config from assets
    final String assetContent =
        await rootBundle.loadString('assets/config/malagasy_refs.json');
    final Map<String, dynamic> devConfig = jsonDecode(assetContent);

    // 2. Cross-reference with AppText Malagasy translations
    final List<MalagasyWordRef> generated = [];

    devConfig.forEach((key, data) {
      // Only include if key exists in dev config AND has shouldDisplay true
      if (data['shouldDisplay'] == true) {
        // Priority: Use 'expression' from JSON. Fallback: Use AppText Malagasy translation.
        final String? jsonExpression = data['expression'];
        final String malagasyWord = (jsonExpression != null && jsonExpression.isNotEmpty)
            ? jsonExpression
            : AppText.trFor('mg', key);
        
        generated.add(MalagasyWordRef(
          key: key,
          word: malagasyWord,
          description: data['description'],
          hasWebsiteRef: data['hasWebsiteRef'],
          shouldDisplay: data['shouldDisplay'],
        ));
      }
    });

    // Sort alphabetically by word
    generated.sort((a, b) => a.word.compareTo(b.word));
    _references = generated;

    // 3. Save to local storage for future launches
    await localFile.writeAsString(jsonEncode(_references.map((r) => r.toJson()).toList()));
  }
}
