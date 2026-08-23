import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application language manager.
///
/// The chosen language is stored in the shared preferences and is used
/// to resolve interface strings through [AppText]. The default language
/// is English.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _prefKey = 'language';
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = <String>['en', 'fr', 'mg'];

  String _language = defaultLanguage;

  String get language => _language;

  /// Loads the saved language, or detects it automatically on first launch
  /// based on the user's country and system language.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefKey);

    if (saved != null && supportedLanguages.contains(saved)) {
      _language = saved;
    } else {
      // Automatic detection for first launch
      final Locale systemLocale = PlatformDispatcher.instance.locale;
      final String? countryCode = systemLocale.countryCode?.toUpperCase();
      final String languageCode = systemLocale.languageCode.toLowerCase();

      if (countryCode == 'MG') {
        _language = 'mg';
      } else if (_isFrancophone(countryCode, languageCode)) {
        _language = 'fr';
      } else {
        _language = 'en';
      }
    }
  }

  bool _isFrancophone(String? countryCode, String languageCode) {
    // If the phone is already in French, it's a safe bet.
    if (languageCode == 'fr') return true;

    // List of major francophone countries (ISO codes)
    const Set<String> francophoneCountries = {
      'FR', 'BE', 'CH', 'CA', 'LU', 'MC', 'SN', 'CI', 'CM', 'CD',
      'CG', 'GA', 'GN', 'NE', 'TG', 'BJ', 'BF', 'BI', 'RW', 'KM',
      'DJ', 'HT', 'VU', 'SC', 'TD', 'ML', 'MA', 'DZ', 'TN'
    };

    return countryCode != null && francophoneCountries.contains(countryCode);
  }

  /// Saves and applies the new language, then notifies listeners so the
  /// whole interface re-renders with the new strings.
  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language);
  }
}

/// Interface strings, resolved according to the current language.
///
/// Values may contain named parameters `{name}`, replaced when [tr]
/// is called.
class AppText {
  AppText._();

  static const Map<String, String> _en = <String, String>{
    // Home
    'all_notes': 'All notes',
    'note': 'Note',
    'notes': 'Notes',
    'search': 'Search',
    'sorted_by': 'Sorted by {sort}',
    'no_note_selected': 'No note selected',
    'all_notes_selected': 'All {count} notes are selected',
    'notes_selected': '{count}/{total} notes selected',
    'single_note_selected': '{count} single note selected',
    'delete_note': 'Delete note',
    'delete_notes': 'Delete {count} notes',
    'delete_all_notes': 'Delete all notes',
    'delete': 'Delete',
    'select_all': 'Select all',
    'select_none': 'Select none',
    'note_deleted': 'Note deleted',
    'undo': 'Undo',
    'save_before_leave': 'Save before leaving',
    'save': 'Save',
    'title_here': 'Title here',
    'content_here': 'Note content here',
    'content_empty': 'Content cannot be empty',
    'type_to_search': 'Type to search',
    'no_item_found': 'No item found',
    'no_note_found': 'No note found',
    'single_result': '{count} single matching result',
    'results': '{count} matching results',
    'confirm_question': 'Are you sure you want to continue?',
    'quit': 'Leave',
    'cancel': 'Cancel',
    'no_data': 'No data',
    'edit_note': 'Edit note',
    'add_note': 'Add note',
    'notes_section': 'Notes',
    'title': 'Title',
    'content': 'Content',
    'important': 'Important',
    'save_changes': 'Save changes',
    'about_description':
        'The main goal of Tano is to provide a simple tool that lets you write notes to keep your ideas, create to-do lists and organize your projects at the same place. Tano prioritizes ease of use over bells and whistles.',
    'close_button': 'Close',
    'home': 'Home',
    'about': 'About',
    'settings': 'Settings',
    'colour': 'Colour',
    'option_image': 'Choose image',
    'option_checklist': 'Checklist',
    'option_link': 'Link a note',
    'option_attachment': 'Attachment',
    'option_collaborators': 'Collaborators',
    'option_share': 'Share',
    'option_pin': 'Pin',
    'option_find': 'Find in note',
    'option_move': 'Move to',
    'option_lock': 'Lock',
    // Menu
    'menu_display': 'Display',
    'menu_list': 'List',
    'menu_grid': 'Grid',
    'menu_sorting': 'Sorting',
    'menu_theme': 'Appearance',
    'theme_automatic': 'Automatic',
    'menu_date': 'Date',
    'menu_title': 'Title',
    'menu_favorites': 'Important',
    'menu_theme_sort': 'Theme',
    'menu_descending': 'Descending',
    'menu_language': 'Language',
    'menu_english': 'English',
    'menu_french': 'French',
    'menu_malagasy': 'Malagasy',
    'menu_view': 'View',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'theme_system': 'System',
    'legacy_version': 'v 0.1.0',
    'language_references': 'Language References',
  };

  static const Map<String, String> _fr = <String, String>{
    // Home
    'all_notes': 'Toutes les notes',
    'note': 'Note',
    'notes': 'Notes',
    'search': 'Rechercher',
    'sorted_by': 'Triage par {sort}',
    'no_note_selected': 'Aucune note sélectionnée',
    'all_notes_selected': 'Toutes les {count} notes sont sélectionnées',
    'notes_selected': '{count}/{total} notes sélectionnées',
    'single_note_selected': '{count} seule note sélectionnée',
    'delete_note': 'Supprimer la note',
    'delete_notes': 'Supprimer les {count} notes',
    'delete_all_notes': 'Supprimer toutes les notes',
    'delete': 'Supprimer',
    'select_all': 'Tout',
    'select_none': 'Rien',
    'note_deleted': 'Note supprimée',
    'undo': 'Annuler',
    'save_before_leave': 'Enregistrer avant de quitter',
    'save': 'Enregistrer',
    'title_here': 'Le titre ici',
    'content_here': 'Le contenu de la note ici',
    'content_empty': 'Le contenu ne peut pas être vide',
    'type_to_search': 'Taper pour rechercher',
    'no_item_found': 'Aucun élément trouvé',
    'no_note_found': 'Aucune note trouvée',
    'single_result': '{count} seul résultat correspondant',
    'results': '{count} résultats correspondants',
    'confirm_question': 'Voulez-vous vraiment continuer ?',
    'quit': 'Quitter',
    'cancel': 'Annuler',
    'no_data': 'Pas de donnée',
    'edit_note': 'Modifier la note',
    'add_note': 'Ajouter une note',
    'notes_section': 'Notes',
    'title': 'Titre',
    'content': 'Contenu',
    'important': "Important",
    'save_changes': 'Enregistrer',
    'about_description':
        "TanoNote est un simple outil de prise de note qui pourra, je l'espère vivement, vous être utile pour sauvegarder vos idées.\nJe vous invite à me faire part de vos remarques et conseils pour me donner le plaisir de continuer à l'améliorer. Merci.",
    'close_button': 'Fermer',
    'home': 'Accueil',
    'about': 'À propos',
    'settings': 'Paramètres',
    'colour': 'Couleur',
    'option_image': 'Choisir image',
    'option_checklist': 'Checklist',
    'option_link': 'Lier une note',
    'option_attachment': 'Pièce jointe',
    'option_collaborators': 'Collaborateurs',
    'option_share': 'Partager',
    'option_pin': 'Épingler',
    'option_find': 'Chercher dans la note',
    'option_move': 'Déplacer vers',
    'option_lock': 'Verrouiller',
    // Menu
    'menu_display': 'Affichage',
    'menu_list': 'Liste',
    'menu_grid': 'Grille',
    'menu_sorting': 'Triage',
    'menu_theme': 'Apparence',
    'theme_automatic': 'Automatique',
    'menu_date': 'Date',
    'menu_title': 'Titre',
    'menu_favorites': 'Important',
    'menu_theme_sort': 'Thème',
    'menu_descending': 'Décroissant',
    'menu_language': 'Langue',
    'menu_english': 'Anglais',
    'menu_french': 'Français',
    'menu_malagasy': 'Malagasy',
    'menu_view': 'Vue',
    'theme_light': 'Clair',
    'theme_dark': 'Sombre',
    'theme_system': 'Système',
    'legacy_version': 'v 0.1.0',
    'language_references': 'Références Linguistiques',
  };

  static const Map<String, String> _mg = <String, String>{
    // Home
    'all_notes': 'Naoty rehetra',
    'note': 'Naoty',
    'notes': 'Naoty',
    'search': 'Karohy',
    'sorted_by': 'Voalamina araka ny {sort}',
    'no_note_selected': 'Tsy misy naoty voafantina',
    'all_notes_selected': 'Voafantina daholo ny naoty {count}',
    'notes_selected': 'Naoty {count}/{total} voafantina',
    'single_note_selected': 'Naoty {count} voafantina',
    'delete_note': 'Hamafa ny naoty',
    'delete_notes': 'Hamafa naoty {count}',
    'delete_all_notes': 'Hamafa ny naoty rehetra',
    'delete': 'Fafao',
    'select_all': 'Rehetra',
    'select_none': 'Tsy misy',
    'note_deleted': 'Voafafa ny naoty',
    'undo': 'Avereno',
    'save_before_leave': 'Tehirizina alohan\'ny hiala',
    'save': 'Tehirizo',
    'title_here': 'Lohateny eto',
    'content_here': 'Votoatiny eto',
    'content_empty': 'Tsy mahazo miala maina ny votoatiny',
    'type_to_search': 'Soraty izay karohina',
    'no_item_found': 'Tsy nisy zavatra hita',
    'no_note_found': 'Tsy nisy naoty hita',
    'single_result': 'Valiny {count} hita',
    'results': 'Valiny {count} hita',
    'confirm_question': 'Tena te hanohy ve ianao?',
    'quit': 'Hiala',
    'cancel': 'Atsaharo',
    'no_data': 'Tsy misy angona',
    'edit_note': 'Hanova naoty',
    'add_note': 'Hanampy naoty',
    'notes_section': 'Naoty',
    'title': 'Lohateny',
    'content': 'Votoatiny',
    'important': 'Zava-dehibe',
    'save_changes': 'Tehirizo',
    'about_description':
        'Ny tanjona lehibe amin\'ny Tano dia ny hanolotra fitaovana tsotra ahafahanao manoratra naoty hitahirizana ny hevitrao, hamoronana lisitra tokony hatao ary handaminana ny tetikasanao amin\'ny toerana iray ihany.',
    'close_button': 'Hidio',
    'home': 'Fandraisana',
    'about': 'Momba ny',
    'settings': 'Fikirana',
    'colour': 'Loko',
    'option_image': 'Hifidy sary',
    'option_checklist': 'Lisitra',
    'option_link': 'Hampifandray naoty',
    'option_attachment': 'Rakitra ampiana',
    'option_collaborators': 'Mpiara-miasa',
    'option_share': 'Hizara',
    'option_pin': 'Hatao eo ambony',
    'option_find': 'Karohy ao anaty naoty',
    'option_move': 'Hafindra any amin\'ny',
    'option_lock': 'Hahidy',
    // Menu
    'menu_display': 'Fampisehoana',
    'menu_list': 'Lisitra',
    'menu_grid': 'Efajoro',
    'menu_sorting': 'Filaminana',
    'menu_theme': 'Endrika',
    'theme_automatic': 'Ho azy',
    'menu_date': 'Daty',
    'menu_title': 'Lohateny',
    'menu_favorites': 'Zava-dehibe',
    'menu_theme_sort': 'Loko',
    'menu_descending': 'Mifanohitra',
    'menu_language': 'Fiteny',
    'menu_english': 'Anglisy',
    'menu_french': 'Frantsay',
    'menu_malagasy': 'Malagasy',
    'menu_view': 'Sary',
    'theme_light': 'Mazava',
    'theme_dark': 'Maizina',
    'theme_system': 'Rafi-pifandraisana',
    'legacy_version': 'v 0.1.0',
    'language_references': 'Rakiteny tsotra',
  };

  /// Returns the string associated with [key] in the current language,
  /// replacing the `{name}` parameters provided in [params].
  static String tr(String key, [Map<String, String>? params]) {
    return trFor(LocaleController.instance.language, key, params);
  }

  /// Returns the string associated with [key] in a specific language.
  static String trFor(String lang, String key, [Map<String, String>? params]) {
    final Map<String, String> table = switch (lang) {
      'fr' => _fr,
      'mg' => _mg,
      _ => _en,
    };
    String text = table[key] ?? _en[key] ?? key;
    if (params != null) {
      params.forEach((String name, String value) {
        text = text.replaceAll('{$name}', value);
      });
    }
    return text;
  }
}
