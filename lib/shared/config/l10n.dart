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
  static const List<String> supportedLanguages = <String>['en', 'fr'];

  String _language = defaultLanguage;

  String get language => _language;

  /// Loads the saved language, or falls back to the default language
  /// if no preference exists.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefKey);
    _language = supportedLanguages.contains(saved) ? saved! : defaultLanguage;
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
    'note': 'note',
    'notes': 'notes',
    'search': 'Search',
    'sorted_by': 'Sorted by {sort}',
    'no_note_selected': 'No note selected',
    'all_notes_selected': 'All {count} notes are selected',
    'notes_selected': '{count}/{total} notes selected',
    'single_note_selected': '{count} single note selected',
    'delete_note': 'Delete note',
    'delete_notes': 'Delete {count} notes',
    'delete_all_notes': 'Delete all notes',
    'delete': 'delete',
    'select_all': 'Select all',
    'select_none': 'Select none',
    'note_deleted': 'Note deleted',
    'undo': 'UNDO',
    'save_before_leave': 'Save before leaving',
    'save': 'save',
    'title_here': 'Title here',
    'content_here': 'Note content here',
    'content_empty': 'Content cannot be empty',
    'type_to_search': 'Type to search',
    'no_item_found': 'No item found',
    'no_note_found': 'No note found',
    'single_result': '{count} single matching result',
    'results': '{count} matching results',
    'confirm_question': 'Are you sure you want to continue?',
    'quit': 'LEAVE',
    'cancel': 'CANCEL',
    'no_data': 'No data',
    'edit_note': 'Edit note',
    'add_note': 'Add note',
    'notes_section': 'Notes',
    'title': 'Title',
    'content': 'Content',
    'important': 'This is important',
    'save_changes': 'Save changes',
    'about_description':
        'The main goal of Tano is to provide a simple tool that lets you write notes to keep your ideas, create to-do lists and organize your projects at the same place. Tano prioritizes ease of use over bells and whistles.',
    'close_button': 'CLOSE',
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
    'menu_theme': 'Theme',
    'menu_date': 'Date',
    'menu_title': 'Title',
    'menu_favorites': 'Important',
    'menu_category': 'Category',
    'menu_language': 'Language',
    'menu_english': 'English',
    'menu_french': 'French',
    'menu_view': 'View',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'theme_system': 'System',
    'legacy_version': 'v 0.1.0',
  };

  static const Map<String, String> _fr = <String, String>{
    // Home
    'all_notes': 'Toutes les notes',
    'note': 'note',
    'notes': 'notes',
    'search': 'Rechercher',
    'sorted_by': 'Triage par {sort}',
    'no_note_selected': 'Aucune note sélectionnée',
    'all_notes_selected': 'Toutes les {count} notes sont sélectionnées',
    'notes_selected': '{count}/{total} notes sélectionnées',
    'single_note_selected': '{count} seule note sélectionnée',
    'delete_note': 'Supprimer la note',
    'delete_notes': 'Supprimer les {count} notes',
    'delete_all_notes': 'Supprimer toutes les notes',
    'delete': 'supprimer',
    'select_all': 'Tout sélectionner',
    'select_none': 'Tout désélectionner',
    'note_deleted': 'Note supprimée',
    'undo': 'ANNULER',
    'save_before_leave': 'Enregistrer avant de quitter',
    'save': 'enregistrer',
    'title_here': 'Le titre ici',
    'content_here': 'Le contenu de la note ici',
    'content_empty': 'Le contenu ne peut pas être vide',
    'type_to_search': 'Taper pour rechercher',
    'no_item_found': 'Aucun élément trouvé',
    'no_note_found': 'Aucune note trouvée',
    'single_result': '{count} seul résultat correspondant',
    'results': '{count} résultats correspondants',
    'confirm_question': 'Voulez-vous vraiment continuer ?',
    'quit': 'QUITTER',
    'cancel': 'ANNULER',
    'no_data': 'Pas de donnée',
    'edit_note': 'Modifier la note',
    'add_note': 'Ajouter une note',
    'notes_section': 'Notes',
    'title': 'Titre',
    'content': 'Contenu',
    'important': "C'est important",
    'save_changes': 'Enregistrer',
    'about_description':
        "TanoNote est un simple outil de prise de note qui pourra, je l'espère vivement, vous être utile pour sauvegarder vos idées.\nJe vous invite à me faire part de vos remarques et conseils pour me donner le plaisir de continuer à l'améliorer. Merci.",
    'close_button': 'FERMER',
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
    'menu_theme': 'Thème',
    'menu_date': 'Date',
    'menu_title': 'Titre',
    'menu_favorites': 'Important',
    'menu_category': 'Catégorie',
    'menu_language': 'Langue',
    'menu_english': 'Anglais',
    'menu_french': 'Français',
    'menu_view': 'Vue',
    'theme_light': 'Clair',
    'theme_dark': 'Sombre',
    'theme_system': 'Système',
    'legacy_version': 'v 0.1.0',
  };

  /// Returns the string associated with [key] in the current language,
  /// replacing the `{name}` parameters provided in [params].
  static String tr(String key, [Map<String, String>? params]) {
    final String lang = LocaleController.instance.language;
    final Map<String, String> table = lang == 'fr' ? _fr : _en;
    String text = table[key] ?? _en[key] ?? key;
    if (params != null) {
      params.forEach((String name, String value) {
        text = text.replaceAll('{$name}', value);
      });
    }
    return text;
  }
}
