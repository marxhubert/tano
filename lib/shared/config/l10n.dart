import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

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
    final SecurePreferences prefs = await SecurePreferences.getInstance();
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
    final SecurePreferences prefs = await SecurePreferences.getInstance();
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
    'all_notes': 'My notes',
    'my_folders': 'My folders',
    'search_results': 'Results',
    'add_folder': 'Add folder',
    'folder_name': 'Folder name',
    'folder_empty': 'This folder is empty',
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
    'reset': 'Reset',
    'select_all': 'All',
    'select_none': 'None',
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
    'retry': 'Retry',
    'data_transfer_title': 'Import & export',
    'desc_export_data':
        'Save your notes and attachments to a .tano file, encrypted or not.',
    'desc_import_data':
        'Add notes and attachments from a .tano file. Existing notes are kept.',
    'option_export_before_reset': 'Export my data first',
    'desc_export_before_reset':
        'Strongly recommended: deleted notes cannot be recovered. Export a copy first.',
    'developer_reset': 'Developer reset',
    'export_data': 'Export data',
    'import_data': 'Import data',
    'export_action': 'Export',
    'import_action': 'Import',
    'export_encrypt': 'Encrypt the export',
    'export_password': 'Password',
    'export_password_hint': '8 characters minimum',
    'password_too_short': 'The password must be at least 8 characters.',
    'export_locked_warning':
        'Some notes are locked: a cleartext export will unlock them.',
    'export_done': 'Export saved.',
    'import_password_title': 'Encrypted export',
    'import_password_message': 'Enter the password of this export.',
    'import_failed': 'Import failed',
    'import_done':
        '{added} notes added, {skipped} skipped, {unlocked} unlocked.',
    'import_clear_warning':
        'Cleartext exports are not protected. Keep them safe.',
    'quit_app': 'Quit',
    'load_error_title': 'Unable to load your notes',
    'load_error_message':
        'Something went wrong while opening the app. You can try again.',
    'cancel': 'Cancel',
    'ok': 'OK',
    'back': 'Back',
    'no_title': 'No title',
    'no_data': 'No data',
    'edit_note': 'Edit note',
    'add_note': 'Add note',
    'find_in_note': 'Find in note',
    'chars': 'chars',
    'notes_section': 'Notes',
    'title': 'Title',
    'content': 'Content',
    'important': 'Important',
    'save_changes': 'Save changes',
    'about_description':
        'TanoNote is a minimal, secure, and fast note-taking app designed to keep your ideas organized and your mind focused. It prioritizes privacy by keeping all your data exclusively on your device.',
    'about_cta':
        'Help us grow and improve TanoNote! Your support allows us to keep the app free and private for everyone. Consider taking action below:',
    'about_support': 'Support the project',
    'about_premium': 'Get Premium version',
    'about_more': 'You may also want (anonymously):',
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
    'option_unlock': 'Unlock',
    'auth_reason': 'Authenticate to access the note',
    'delete_locked_error': 'Locked notes cannot be deleted',
    'lock_unavailable_title': 'Cannot lock this note',
    'lock_requires_device_lock': 'Set up a screen lock (passcode or biometrics) to lock notes',
    'option_check_update': 'Check for update',
    'option_feedback': 'Give feedback',
    'option_bug_report': 'Allow bug report',
    'option_recycle_bin': 'Recycle bin',
    'option_reset_data': 'Reset data',
    'desc_bug_report': 'Help us improve TanoNote by automatically sending anonymous crash reports and performance data.',
    'desc_recycle_bin': 'Deleted notes are kept in the recycle bin for 30 days before being permanently removed.',
    'desc_reset_data': 'Resetting data will permanently delete all your notes and preferences. This action cannot be undone.',
    'option_delete_data': 'Delete all data',
    'option_delete_prefs': 'Delete all preferences',
    'desc_delete_data': 'This will permanently remove all your notes and attachments.',
    'desc_delete_prefs': 'This will reset all your settings (theme, language, sorting) to their default values.',
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
    'attachment': 'Attachment',
    'attachments': 'Attachments',
    'licenses': 'Licenses',
    'license_disclaimer': 'This has been translated from the original English version by an AI, then reviewed and verified by a human. However, translation errors may still occur. We apologize in advance and thank you for your understanding.',
    'license_view_original': 'View original version',
    'lang_en': 'ENGLISH',
    'lang_fr': 'FRENCH',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Delete photo',
  };

  static const Map<String, String> _fr = <String, String>{
    // Home
    'all_notes': 'Mes notes',
    'my_folders': 'Mes dossiers',
    'search_results': 'Résultats',
    'add_folder': 'Ajouter un dossier',
    'folder_name': 'Nom du dossier',
    'folder_empty': 'Ce dossier est vide',
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
    'reset': 'Réinitialiser',
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
    'retry': 'Réessayer',
    'data_transfer_title': 'Import & export',
    'desc_export_data':
        'Enregistrez vos notes et pièces jointes dans un fichier .tano, chiffré ou non.',
    'desc_import_data':
        "Ajoutez les notes et pièces jointes d'un fichier .tano. Les notes existantes sont conservées.",
    'option_export_before_reset': 'Exporter mes données avant',
    'desc_export_before_reset':
        'Fortement recommandé : une fois supprimées, vos notes ne peuvent pas être récupérées. Exportez-en une copie avant.',
    'developer_reset': 'Réinitialisation développeur',
    'export_data': 'Exporter les données',
    'import_data': 'Importer des données',
    'export_action': 'Exporter',
    'import_action': 'Importer',
    'export_encrypt': "Chiffrer l'export",
    'export_password': 'Mot de passe',
    'export_password_hint': '8 caractères minimum',
    'password_too_short': 'Le mot de passe doit faire au moins 8 caractères.',
    'export_locked_warning':
        'Des notes sont verrouillées : un export en clair les déverrouillera.',
    'export_done': 'Export enregistré.',
    'import_password_title': 'Export chiffré',
    'import_password_message': "Saisissez le mot de passe de cet export.",
    'import_failed': "Échec de l'import",
    'import_done':
        '{added} notes ajoutées, {skipped} ignorées, {unlocked} déverrouillées.',
    'import_clear_warning':
        "Les exports en clair ne sont pas protégés. Gardez-les en sécurité.",
    'quit_app': 'Quitter',
    'load_error_title': 'Impossible de charger vos notes',
    'load_error_message':
        "Une erreur est survenue à l'ouverture de l'application. Vous pouvez réessayer.",
    'cancel': 'Annuler',
    'ok': 'OK',
    'back': 'Retour',
    'no_title': 'Sans titre',
    'no_data': 'Pas de donnée',
    'edit_note': 'Modifier la note',
    'add_note': 'Ajouter une note',
    'find_in_note': 'Rechercher dans la note',
    'chars': 'caractères',
    'notes_section': 'Notes',
    'title': 'Titre',
    'content': 'Contenu',
    'important': "Important",
    'save_changes': 'Enregistrer',
    'about_description':
        "TanoNote est une application de prise de notes minimaliste, sécurisée et rapide, conçue pour organiser vos idées tout en restant concentré. Elle privilégie votre vie privée en conservant toutes vos données exclusivement sur votre appareil.",
    'about_cta':
        "Aidez-nous à faire grandir et améliorer TanoNote ! Votre soutien nous permet de garder l'application gratuite et privée pour tous. Voici comment vous pouvez nous aider :",
    'about_support': "Soutenir le projet",
    'about_premium': "Passer à la version Premium",
    'about_more': "Vous pouvez également (et de façon anonyme) :",
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
    'option_unlock': 'Déverrouiller',
    'auth_reason': 'Authentifiez-vous pour accéder à la note',
    'delete_locked_error': 'Les notes verrouillées ne peuvent pas être supprimées',
    'lock_unavailable_title': 'Impossible de verrouiller la note',
    'lock_requires_device_lock': 'Configurez un verrou d\'écran (code ou biométrie) pour verrouiller une note',
    'option_check_update': 'Mise à jour',
    'option_feedback': 'Donner un avis',
    'option_bug_report': 'Autoriser les rapports de bug',
    'option_recycle_bin': 'Corbeille',
    'option_reset_data': 'Réinitialiser',
    'desc_bug_report': 'Aidez-nous à améliorer TanoNote en envoyant automatiquement des rapports d\'erreur anonymes.',
    'desc_recycle_bin': 'Les notes supprimées sont conservées dans la corbeille pendant 30 jours avant d\'être définitivement effacées.',
    'desc_reset_data': 'La réinitialisation supprimera définitivement toutes vos notes et préférences. Cette action est irréversible.',
    'option_delete_data': 'Supprimer toutes les données',
    'option_delete_prefs': 'Supprimer toutes les préférences',
    'desc_delete_data': 'Ceci supprimera définitivement toutes vos notes et pièces jointes.',
    'desc_delete_prefs': 'Ceci réinitialisera tous vos réglages (thème, langue, tri) à leurs valeurs par défaut.',
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
    'attachment': 'Pièce jointe',
    'attachments': 'Pièces jointes',
    'licenses': 'Licences',
    'license_disclaimer': "Ceci a été traduit de la version originale anglaise par une IA, puis relu et vérifié par un humain. Toutefois, des erreurs de traduction peuvent encore subsister. Nous nous en excusons par avance et vous remercions de votre compréhension.",
    'license_view_original': "Voir la version originale",
    'lang_en': 'ANGLAIS',
    'lang_fr': 'FRANÇAIS',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Supprimer la photo',
  };

  static const Map<String, String> _mg = <String, String>{
    // Home
    'all_notes': 'Ireo tanoko',
    'my_folders': 'Ireo rakitra',
    'search_results': 'Vokatra',
    'add_folder': 'Hampiditra rakitra',
    'folder_name': 'Anaran\'ny rakitra',
    'folder_empty': 'Foana ity rakitra ity',
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
    'reset': 'Fafao',
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
    'retry': 'Andramo indray',
    'data_transfer_title': 'Fanafarana & fanondranana',
    'desc_export_data':
        'Tehirizo ao anaty rakitra .tano ny naoty sy ny attache, voahidy na tsia.',
    'desc_import_data':
        'Ampio ao ny naoty sy attache avy amin\'ny rakitra .tano. Voatahiry ny naoty efa misy.',
    'option_export_before_reset': 'Avoahy aloha ny angona',
    'desc_export_before_reset':
        'Tena atolotra: tsy azo averina ny naoty voafafa. Avoahy aloha ny kopian\'izy ireo.',
    'developer_reset': 'Fanavaozana ho an\'ny mpamorona',
    'export_data': 'Avoaka ny angona',
    'import_data': 'Hampiditra angona',
    'export_action': 'Avoaka',
    'import_action': 'Hampiditra',
    'export_encrypt': 'Hidio ny fanondranana',
    'export_password': 'Teny miafina',
    'export_password_hint': '8 litera farafahakeliny',
    'password_too_short': 'Tokony 8 litera Farafahakeliny ny teny miafina.',
    'export_locked_warning':
        'Misy naoty voahidy: ny fanondranana mazava dia hamaha azy ireo.',
    'export_done': 'Voatahiry ny fanondranana.',
    'import_password_title': 'Fanondranana voahidy',
    'import_password_message': 'Ampidiro ny teny miafina amin\'ity fanondranana ity.',
    'import_failed': 'Tsy nahomby ny fampidirana',
    'import_done':
        '{added} naoty nampidirina, {skipped} nolavina, {unlocked} navahana.',
    'import_clear_warning':
        'Tsy voaaro ny fanondranana mazava. Tano tsara izy ireo.',
    'quit_app': 'Hiala',
    'load_error_title': 'Tsy afaka naka ny naoty',
    'load_error_message':
        'Nisy olana teo am-panokafana ny rindranasa. Afaka manandrana indray ianao.',
    'cancel': 'Atsaharo',
    'ok': 'OK',
    'back': 'Hiverina',
    'no_title': 'Tsy misy lohateny',
    'no_data': 'Tsy misy angona',
    'edit_note': 'Hanova naoty',
    'add_note': 'Hanampy naoty',
    'find_in_note': 'Hikaroka ao anaty naoty',
    'chars': 'litera',
    'notes_section': 'Naoty',
    'title': 'Lohateny',
    'content': 'Votoatiny',
    'important': 'Zava-dehibe',
    'save_changes': 'Tehirizo',
    'about_description':
        "Ny TanoNote dia fitaovana fanoratana tsotra, azo antoka ary haingana natao hanampiana anao amin'ny fandaminana ny hevitrao sy ny fifantohana. Omenay lanja ny tsiambaratelonao ka ao anatin'ny findainao ihany no mipetraka ny angon-drakitrao rehetra.",
    'about_cta':
        "Ampio izahay hampandroso sy hanatsara hatrany ny TanoNote! Ny fanohananao dia mamela anay hihazona ity fitaovana ity ho maimaim-poana sy hanaja ny tsiambaratelon'ny rehetra. Azonao atao ireto manaraka ireto:",
    'about_support': "Hanohana ny tetikasa",
    'about_premium': "Hividy ny dikan-teny Premium",
    'about_more': "Azonao atao koa (sady tsy mila anarana) ny:",
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
    'option_unlock': 'Hovahany',
    'auth_reason': 'Mila famantarana vao afaka mijery ny naoty',
    'delete_locked_error': 'Tsy azo fafana ny naoty voahidy',
    'lock_unavailable_title': 'Tsy azo hidiana ny naoty',
    'lock_requires_device_lock': 'Mametraha hidy efijery (kaody na biometrika) vao afaka manidy naoty',
    'option_check_update': 'Hizaha vao',
    'option_feedback': 'Hanome hevitra',
    'option_bug_report': 'Hamela ny tatitra bug',
    'option_recycle_bin': 'Fitoeram-pako',
    'option_reset_data': 'Hamerina ny angona',
    'desc_bug_report': 'Ampio izahay hanatsara ny TanoNote amin\'ny alalan\'ny fandefasana tatitra momba ny olana miseho amin\'ny fampiasanao ny rindrankajy.',
    'desc_recycle_bin': 'Ireo naoty voafafa dia voatahiry ao amin\'ny fitoeram-pako mandritra ny 30 andro alohan\'ny hamafana azy tanteraka.',
    'desc_reset_data': 'Ny famerenana ny angona dia hamafa tanteraka ny naoty sy ny fikirana rehetra nataonao. Tsy azo averina intsony izany rehefa voafafa.',
    'option_delete_data': 'Hamafa ny angona rehetra',
    'option_delete_prefs': 'Hamafa ny fikirana rehetra',
    'desc_delete_data': 'Hamafa tanteraka ny naoty sy ny rakitra rehetra izany.',
    'desc_delete_prefs': 'Hamerina ny fikirana rehetra (loko, fiteny, filaminana) amin\'ny teo aloha izany.',
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
    'attachment': 'Rakitra ampiana',
    'attachments': 'Rakitra ampiana',
    'licenses': 'Lisansa',
    'license_disclaimer': "Ity dia nadika avy tamin'ny dikan-teny anglisy tany am-boalohany tamin'ny alalan'ny AI, nefa efa novakiana sy nohamarinin'olombelona. Na izany aza, mety mbola hisy ny hadisoana amin'ny fandikan-teny. Mifona mialoha izahay ary misaotra anareo amin'ny fahatakarana.",
    'license_view_original': "Hijery ny dikan-teny tany am-boalohany",
    'lang_en': 'ANGLISY',
    'lang_fr': 'FRANTSAY',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Hamafa ny sary',
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
