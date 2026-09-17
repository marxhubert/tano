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
      'FR',
      'BE',
      'CH',
      'CA',
      'LU',
      'MC',
      'SN',
      'CI',
      'CM',
      'CD',
      'CG',
      'GA',
      'GN',
      'NE',
      'TG',
      'BJ',
      'BF',
      'BI',
      'RW',
      'KM',
      'DJ',
      'HT',
      'VU',
      'SC',
      'TD',
      'ML',
      'MA',
      'DZ',
      'TN',
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
/// [AppText.count] builds the "N thing(s)" labels used by metadata lines and
/// the undo message.
///
/// Values may contain named parameters `{name}`, replaced when [tr]
/// is called.
class AppText {
  AppText._();

  /// "1 note", "3 notes", "1 folder"… The plural key is used above one.
  static String count(int value, String singular, String plural) =>
      '$value ${tr(value > 1 ? plural : singular)}';

  /// Every translatable string, by key.
  static const Map<String, String> _en = <String, String>{
    // Home
    'all_notes': 'My notes',
    'my_folders': 'My folders',
    'folder': 'folder',
    'folders': 'folders',
    'no_folder': 'Home',
    'delete_folder': 'Delete folder',
    'delete_folder_question':
        'This folder contains {count} notes. Delete them with the folder?',
    'search_results': 'Results',
    'add_folder': 'Add folder',
    'folder_name': 'Folder name',
    'folder_empty': 'This folder is empty',
    'note': 'note',
    'notes': 'notes',
    'search': 'Search',
    'no_note_selected': 'No note selected',
    'all_notes_selected': 'All {count} notes are selected',
    'notes_selected': '{count}/{total} notes selected',
    'single_note_selected': '{count} single note selected',
    'single_folder_selected': '{count} single folder selected',
    'folders_selected': '{count}/{total} folders selected',
    'all_folders_selected': 'All {count} folders are selected',
    'delete_note': 'Delete note',
    'delete_notes': 'Delete {count} notes',
    'delete_all_notes': 'Delete all notes',
    'delete': 'Delete',
    'reset': 'Reset',
    'select_all': 'All',
    'select_none': 'None',
    'note_deleted': 'Note deleted',
    'deleted': 'deleted',
    'undo': 'Undo',
    'save_before_leave': 'Save before leaving',
    'save': 'Save',
    'title_here': 'Title here',
    'content_empty': 'Content cannot be empty',
    'no_note_found': 'No note found',
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
    'empty': 'Empty',
    'edit_note': 'Edit note',
    'add_note': 'Add note',
    'find_in_note': 'Find in note',
    'chars': 'chars',
    'folders_group': 'Folders',
    'notes_group': 'Notes',
    'title': 'Title',
    'content': 'Content',
    'important': 'Important',
    'about_description':
        'TanoNote is a minimal, secure, and fast note-taking app designed to keep your ideas organized and your mind focused. It prioritizes privacy by keeping all your data exclusively on your device.',
    'about_cta':
        'Help us grow and improve TanoNote! Your support allows us to keep the app free and private for everyone. Consider taking action below:',
    'about_premium': 'Get Premium version',
    'about_more': 'You may also want (anonymously):',
    'close_button': 'Close',
    // Accessibility labels for icon-only actions.
    'more': 'More',
    'redo': 'Redo',
    'add': 'Add',
    'clear': 'Clear',
    'sort_by': 'Sort by',
    'sort_direction': 'Sort direction',
    'toggle_theme': 'Switch theme',
    'empty_trash': 'Empty the bin',
    'reduce': 'Reduce',
    'previous': 'Previous',
    'next': 'Next',
    'home': 'Home',
    'about': 'About',
    'settings': 'Settings',
    'option_image': 'Choose image',
    'corrupted_image': 'Corrupted image',
    'option_checklist': 'Checklist',
    'option_link': 'Link a note',
    'option_attachment': 'Attachment',
    'edit': 'Edit',
    'option_find': 'Find in note',
    'option_move': 'Move to',
    'option_lock': 'Lock',
    'option_unlock': 'Unlock',
    'auth_reason': 'Authenticate to access the note',
    'delete_locked_error': 'Locked notes cannot be deleted',
    'lock_unavailable_title': 'Cannot lock this note',
    'lock_requires_device_lock':
        'Set up a screen lock (passcode or biometrics) to lock notes',
    'option_bug_report': 'Allow bug report',
    'option_update': 'Check for update',
    'update_up_to_date': 'You are up to date',
    'update_unavailable': 'Update check unavailable',
    'option_recycle_bin': 'Recycle bin',
    'option_reset_data': 'Reset data',
    'desc_bug_report':
        'Help us improve TanoNote by sending anonymous crash reports. No IP address, no stable identifier, no note content — and you can turn it off at any time.',
    'desc_recycle_bin':
        'Deleted notes are kept in the recycle bin for 30 days before being permanently removed.',
    'desc_reset_data':
        'Resetting data will permanently delete all your notes and preferences. This action cannot be undone.',
    'option_delete_data': 'Delete all data',
    'option_delete_prefs': 'Delete all preferences',
    'desc_delete_data':
        'This will permanently remove all your notes and attachments.',
    'desc_delete_prefs':
        'This will reset all your settings (theme, language, sorting) to their default values.',
    // Menu
    'menu_list': 'List',
    'menu_grid': 'Grid',
    'menu_sorting': 'Sorting',
    'menu_theme': 'Appearance',
    'theme_automatic': 'Automatic',
    'menu_date': 'Date',
    'menu_modified': 'Recently modified',
    'menu_title': 'Title',
    'menu_favorites': 'Important',
    'menu_theme_sort': 'Theme',
    'menu_descending': 'Descending',
    'menu_language': 'Language',
    'menu_english': 'English',
    'menu_french': 'French',
    'menu_malagasy': 'Malagasy',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'language_references': 'Language References',
    'attachment': 'Attachment',
    'attachments': 'Attachments',
    // Privacy policy. The canonical text lives in docs/confidentialite.md.
    'privacy': 'Privacy policy',
    'privacy_intro':
        'TanoNote has no account and no server. Everything you write stays on your device; nothing is sent anywhere unless you explicitly allow it.',
    'privacy_local_title': 'Data stored on your device',
    'privacy_local_body':
        'Your notes, folders, attachments and preferences are saved locally, in the private storage of the app.',
    'privacy_encryption_title': 'Encryption at rest',
    'privacy_encryption_body':
        'The database and the attachments are encrypted on the device. The key is kept in the secure storage of the system and never leaves it.',
    'privacy_crash_title': 'Crash reports (optional)',
    'privacy_crash_body':
        'Off by default. If you turn on “{option_bug_report}”, technical data about a crash — the error, the app version, the device model and the OS version — is sent to Sentry (Functional Software, Inc.) so the bug can be fixed. No IP address, no stable identifier and no note content is sent, and no account is created. Turning the switch back off stops every future report.',
    'privacy_updates_title': 'Update check',
    'privacy_updates_body':
        'When you open the About screen, the app asks the store whether a newer version exists. The only thing carried is the name of the app — no account, no identifier, and nothing kept. The check can also be started by hand from that screen.',
    'privacy_tracking_title': 'No tracking, no ads',
    'privacy_tracking_body':
        'TanoNote contains no usage analytics, no advertising and no third-party tracker, and never sells or shares your data. Nothing is collected until you turn the crash reports on.',
    'privacy_delete_title': 'Deleting your data',
    'privacy_delete_body':
        'Everything can be erased from the settings. Because nothing is kept on our side, deleting the app or its data is enough: there is no request to send and no copy left elsewhere.',
    'privacy_updated': 'Last updated: September 2026',
    'licenses': 'Licenses',
    'license_disclaimer':
        'This has been translated from the original English version by an AI, then reviewed and verified by a human. However, translation errors may still occur. We apologize in advance and thank you for your understanding.',
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
    'folder': 'dossier',
    'folders': 'dossiers',
    'no_folder': 'Accueil',
    'delete_folder': 'Supprimer le dossier',
    'delete_folder_question':
        'Ce dossier contient {count} notes. Les supprimer avec le dossier ?',
    'search_results': 'Résultats',
    'add_folder': 'Ajouter un dossier',
    'folder_name': 'Nom du dossier',
    'folder_empty': 'Ce dossier est vide',
    'note': 'note',
    'notes': 'notes',
    'search': 'Rechercher',
    'no_note_selected': 'Aucune note sélectionnée',
    'all_notes_selected': 'Toutes les {count} notes sont sélectionnées',
    'notes_selected': '{count}/{total} notes sélectionnées',
    'single_note_selected': '{count} seule note sélectionnée',
    'single_folder_selected': '{count} seul dossier sélectionné',
    'folders_selected': '{count}/{total} dossiers sélectionnés',
    'all_folders_selected': 'Tous les {count} dossiers sont sélectionnés',
    'delete_note': 'Supprimer la note',
    'delete_notes': 'Supprimer les {count} notes',
    'delete_all_notes': 'Supprimer toutes les notes',
    'delete': 'Supprimer',
    'reset': 'Réinitialiser',
    'select_all': 'Tout',
    'select_none': 'Rien',
    'note_deleted': 'Note supprimée',
    'deleted': 'supprimé(s)',
    'undo': 'Annuler',
    'save_before_leave': 'Enregistrer avant de quitter',
    'save': 'Enregistrer',
    'title_here': 'Le titre ici',
    'content_empty': 'Le contenu ne peut pas être vide',
    'no_note_found': 'Aucune note trouvée',
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
    'empty': 'Vide',
    'edit_note': 'Modifier la note',
    'add_note': 'Ajouter une note',
    'find_in_note': 'Rechercher dans la note',
    'chars': 'caractères',
    'folders_group': 'Dossiers',
    'notes_group': 'Notes',
    'title': 'Titre',
    'content': 'Contenu',
    'important': "Important",
    'about_description':
        "TanoNote est une application de prise de notes minimaliste, sécurisée et rapide, conçue pour organiser vos idées tout en restant concentré. Elle privilégie votre vie privée en conservant toutes vos données exclusivement sur votre appareil.",
    'about_cta':
        "Aidez-nous à faire grandir et améliorer TanoNote ! Votre soutien nous permet de garder l'application gratuite et privée pour tous. Voici comment vous pouvez nous aider :",
    'about_premium': "Passer à la version Premium",
    'about_more': "Vous pouvez également (et de façon anonyme) :",
    'close_button': 'Fermer',
    // Accessibility labels for icon-only actions.
    'more': 'Plus',
    'redo': 'Rétablir',
    'add': 'Ajouter',
    'clear': 'Effacer',
    'sort_by': 'Trier par',
    'sort_direction': 'Sens du tri',
    'toggle_theme': 'Changer de thème',
    'empty_trash': 'Vider la corbeille',
    'reduce': 'Réduire',
    'previous': 'Précédent',
    'next': 'Suivant',
    'home': 'Accueil',
    'about': 'À propos',
    'settings': 'Paramètres',
    'option_image': 'Choisir image',
    'corrupted_image': 'Image corrompue',
    'option_checklist': 'Checklist',
    'option_link': 'Lier une note',
    'option_attachment': 'Pièce jointe',
    'edit': 'Modifier',
    'option_find': 'Chercher dans la note',
    'option_move': 'Déplacer vers',
    'option_lock': 'Verrouiller',
    'option_unlock': 'Déverrouiller',
    'auth_reason': 'Authentifiez-vous pour accéder à la note',
    'delete_locked_error':
        'Les notes verrouillées ne peuvent pas être supprimées',
    'lock_unavailable_title': 'Impossible de verrouiller la note',
    'lock_requires_device_lock':
        'Configurez un verrou d\'écran (code ou biométrie) pour verrouiller une note',
    'option_bug_report': 'Autoriser les rapports de bug',
    'option_update': 'Mise à jour',
    'update_up_to_date': 'Vous êtes à jour',
    'update_unavailable': 'Vérification indisponible',
    'option_recycle_bin': 'Corbeille',
    'option_reset_data': 'Réinitialiser',
    'desc_bug_report':
        'Aidez-nous à améliorer TanoNote en envoyant des rapports d\'erreur anonymes. Aucune adresse IP, aucun identifiant stable, aucun contenu de note — et vous pouvez le désactiver à tout moment.',
    'desc_recycle_bin':
        'Les notes supprimées sont conservées dans la corbeille pendant 30 jours avant d\'être définitivement effacées.',
    'desc_reset_data':
        'La réinitialisation supprimera définitivement toutes vos notes et préférences. Cette action est irréversible.',
    'option_delete_data': 'Supprimer toutes les données',
    'option_delete_prefs': 'Supprimer toutes les préférences',
    'desc_delete_data':
        'Ceci supprimera définitivement toutes vos notes et pièces jointes.',
    'desc_delete_prefs':
        'Ceci réinitialisera tous vos réglages (thème, langue, tri) à leurs valeurs par défaut.',
    // Menu
    'menu_list': 'Liste',
    'menu_grid': 'Grille',
    'menu_sorting': 'Triage',
    'menu_theme': 'Apparence',
    'theme_automatic': 'Automatique',
    'menu_date': 'Date',
    'menu_modified': 'Modifié récemment',
    'menu_title': 'Titre',
    'menu_favorites': 'Important',
    'menu_theme_sort': 'Thème',
    'menu_descending': 'Décroissant',
    'menu_language': 'Langue',
    'menu_english': 'Anglais',
    'menu_french': 'Français',
    'menu_malagasy': 'Malagasy',
    'theme_light': 'Clair',
    'theme_dark': 'Sombre',
    'language_references': 'Références Linguistiques',
    'attachment': 'Pièce jointe',
    'attachments': 'Pièces jointes',
    // Police de confidentialité. Le texte de référence vit dans docs/confidentialite.md.
    'privacy': 'Confidentialité',
    'privacy_intro':
        "TanoNote n'a ni compte ni serveur. Tout ce que vous écrivez reste sur votre appareil ; rien n'est envoyé sans votre accord explicite.",
    'privacy_local_title': 'Données stockées sur votre appareil',
    'privacy_local_body':
        "Vos notes, dossiers, pièces jointes et préférences sont enregistrés localement, dans l'espace privé de l'application.",
    'privacy_encryption_title': 'Chiffrement au repos',
    'privacy_encryption_body':
        "La base de données et les pièces jointes sont chiffrées sur l'appareil. La clé est conservée dans le stockage sécurisé du système et n'en sort jamais.",
    'privacy_crash_title': 'Rapports de crash (facultatif)',
    'privacy_crash_body':
        "Désactivés par défaut. Si vous activez « {option_bug_report} », des données techniques sur le plantage — l'erreur, la version de l'application, le modèle de l'appareil et la version du système — sont envoyées à Sentry (Functional Software, Inc.) pour corriger le bug. Aucune adresse IP, aucun identifiant stable et aucun contenu de note ne sont transmis, et aucun compte n'est créé. Désactiver l'interrupteur arrête définitivement tout envoi.",
    'privacy_updates_title': 'Vérification des mises à jour',
    'privacy_updates_body':
        "Quand vous ouvrez l'écran À propos, l'application demande au store s'il existe une version plus récente. La seule chose transmise est le nom de l'application — aucun compte, aucun identifiant, rien de conservé. La vérification peut aussi être lancée à la main depuis ce même écran.",
    'privacy_tracking_title': 'Aucun pistage, aucune publicité',
    'privacy_tracking_body':
        "TanoNote ne contient ni analyse d'usage, ni publicité, ni traceur tiers, et ne vend ni ne partage vos données. Rien n'est collecté tant que vous n'activez pas les rapports de crash.",
    'privacy_delete_title': 'Supprimer vos données',
    'privacy_delete_body':
        "Tout s'efface depuis les paramètres. Comme rien n'est conservé de notre côté, supprimer l'application ou ses données suffit : aucune demande à envoyer, aucune copie ailleurs.",
    'privacy_updated': 'Dernière mise à jour : septembre 2026',
    'licenses': 'Licences',
    'license_disclaimer':
        "Ceci a été traduit de la version originale anglaise par une IA, puis relu et vérifié par un humain. Toutefois, des erreurs de traduction peuvent encore subsister. Nous nous en excusons par avance et vous remercions de votre compréhension.",
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
    'folder': 'rakitra',
    'folders': 'rakitra',
    'no_folder': 'Fandraisana',
    'delete_folder': 'Fafana ny rakitra',
    'delete_folder_question':
        'Misy {count} naoty ity rakitra ity. Hofafana miaraka aminy ve?',
    'search_results': 'Vokatra',
    'add_folder': 'Hampiditra rakitra',
    'folder_name': 'Anaran\'ny rakitra',
    'folder_empty': 'Foana ity rakitra ity',
    'note': 'naoty',
    'notes': 'naoty',
    'search': 'Karohy',
    'no_note_selected': 'Tsy misy naoty voafantina',
    'all_notes_selected': 'Voafantina daholo ny naoty {count}',
    'notes_selected': 'Naoty {count}/{total} voafantina',
    'single_note_selected': 'Naoty {count} voafantina',
    'single_folder_selected': 'Vosana {count} voafantina',
    'folders_selected': 'Vosana {count}/{total} voafantina',
    'all_folders_selected': 'Voafantina daholo ny vosana {count}',
    'delete_note': 'Hamafa ny naoty',
    'delete_notes': 'Hamafa naoty {count}',
    'delete_all_notes': 'Hamafa ny naoty rehetra',
    'delete': 'Fafao',
    'reset': 'Fafao',
    'select_all': 'Rehetra',
    'select_none': 'Tsy misy',
    'note_deleted': 'Voafafa ny naoty',
    'deleted': 'voafafa',
    'undo': 'Avereno',
    'save_before_leave': 'Tehirizina alohan\'ny hiala',
    'save': 'Tehirizo',
    'title_here': 'Lohateny eto',
    'content_empty': 'Tsy mahazo miala maina ny votoatiny',
    'no_note_found': 'Tsy nisy naoty hita',
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
    'export_encrypt': 'Hidio ny fanondranana',
    'export_password': 'Teny miafina',
    'export_password_hint': '8 litera farafahakeliny',
    'password_too_short': 'Tokony 8 litera Farafahakeliny ny teny miafina.',
    'export_locked_warning':
        'Misy naoty voahidy: ny fanondranana mazava dia hamaha azy ireo.',
    'export_done': 'Voatahiry ny fanondranana.',
    'import_password_title': 'Fanondranana voahidy',
    'import_password_message':
        'Ampidiro ny teny miafina amin\'ity fanondranana ity.',
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
    'empty': 'Foana',
    'edit_note': 'Hanova naoty',
    'add_note': 'Hanampy naoty',
    'find_in_note': 'Hikaroka ao anaty naoty',
    'chars': 'litera',
    'folders_group': 'Rakitra',
    'notes_group': 'Naoty',
    'title': 'Lohateny',
    'content': 'Votoatiny',
    'important': 'Zava-dehibe',
    'about_description':
        "Ny TanoNote dia fitaovana fanoratana tsotra, azo antoka ary haingana natao hanampiana anao amin'ny fandaminana ny hevitrao sy ny fifantohana. Omenay lanja ny tsiambaratelonao ka ao anatin'ny findainao ihany no mipetraka ny angon-drakitrao rehetra.",
    'about_cta':
        "Ampio izahay hampandroso sy hanatsara hatrany ny TanoNote! Ny fanohananao dia mamela anay hihazona ity fitaovana ity ho maimaim-poana sy hanaja ny tsiambaratelon'ny rehetra. Azonao atao ireto manaraka ireto:",
    'about_premium': "Hividy ny dikan-teny Premium",
    'about_more': "Azonao atao koa (sady tsy mila anarana) ny:",
    'close_button': 'Hidio',
    // Accessibility labels for icon-only actions.
    'more': 'Be kokoa',
    'redo': 'Averina',
    'add': 'Hanampy',
    'clear': 'Fafao',
    'sort_by': "Alaharo amin'ny",
    'sort_direction': 'Lalana fandaharana',
    'toggle_theme': 'Hanova endrika',
    'empty_trash': 'Fafao ny fako',
    'reduce': 'Ahena',
    'previous': 'Teo aloha',
    'next': 'Manaraka',
    'home': 'Fandraisana',
    'about': 'Momba ny',
    'settings': 'Fikirana',
    'option_image': 'Hifidy sary',
    'corrupted_image': 'Sary simba',
    'option_checklist': 'Lisitra',
    'option_link': 'Hampifandray naoty',
    'option_attachment': 'Rakitra ampiana',
    'edit': 'Ovay',
    'option_find': 'Karohy ao anaty naoty',
    'option_move': 'Hafindra any amin\'ny',
    'option_lock': 'Hahidy',
    'option_unlock': 'Hovahany',
    'auth_reason': 'Mila famantarana vao afaka mijery ny naoty',
    'delete_locked_error': 'Tsy azo fafana ny naoty voahidy',
    'lock_unavailable_title': 'Tsy azo hidiana ny naoty',
    'lock_requires_device_lock':
        'Mametraha hidy efijery (kaody na biometrika) vao afaka manidy naoty',
    'option_bug_report': 'Hamela ny tatitra bug',
    'option_update': 'Hizaha vao',
    'update_up_to_date': 'Efa farany ianao',
    'update_unavailable': 'Tsy afaka manamarina ny fanavaozana',
    'option_recycle_bin': 'Fitoeram-pako',
    'option_reset_data': 'Hamerina ny angona',
    'desc_bug_report':
        'Ampio izahay hanatsara ny TanoNote amin\'ny fandefasana tatitra momba ny olana tsy misy anarana. Tsy misy adiresy IP, tsy misy famantarana maharitra ary tsy misy votoatin\'ny naoty — ary azonao atao ny mamono azy rehefa tianao.',
    'desc_recycle_bin':
        'Ireo naoty voafafa dia voatahiry ao amin\'ny fitoeram-pako mandritra ny 30 andro alohan\'ny hamafana azy tanteraka.',
    'desc_reset_data':
        'Ny famerenana ny angona dia hamafa tanteraka ny naoty sy ny fikirana rehetra nataonao. Tsy azo averina intsony izany rehefa voafafa.',
    'option_delete_data': 'Hamafa ny angona rehetra',
    'option_delete_prefs': 'Hamafa ny fikirana rehetra',
    'desc_delete_data':
        'Hamafa tanteraka ny naoty sy ny rakitra rehetra izany.',
    'desc_delete_prefs':
        'Hamerina ny fikirana rehetra (loko, fiteny, filaminana) amin\'ny teo aloha izany.',
    // Menu
    'menu_list': 'Lisitra',
    'menu_grid': 'Efajoro',
    'menu_sorting': 'Filaminana',
    'menu_theme': 'Endrika',
    'theme_automatic': 'Ho azy',
    'menu_date': 'Daty',
    'menu_modified': 'Vao novaina',
    'menu_title': 'Lohateny',
    'menu_favorites': 'Zava-dehibe',
    'menu_theme_sort': 'Loko',
    'menu_descending': 'Mifanohitra',
    'menu_language': 'Fiteny',
    'menu_english': 'Anglisy',
    'menu_french': 'Frantsay',
    'menu_malagasy': 'Malagasy',
    'theme_light': 'Mazava',
    'theme_dark': 'Maizina',
    'language_references': 'Rakiteny tsotra',
    'attachment': 'Rakitra ampiana',
    'attachments': 'Rakitra ampiana',
    // Politikan'ny tsiambaratelo. Ny lahatsoratra fototra dia ao amin'ny docs/confidentialite.md.
    'privacy': 'Tsiambaratelo',
    'privacy_intro':
        "Ny TanoNote dia tsy manana kaonty na serivera. Izay rehetra soratanao dia mijanona ao amin'ny findainao; tsy misy alefa raha tsy manaiky ianao.",
    'privacy_local_title': "Angona tehirizina ao amin'ny findainao",
    'privacy_local_body':
        "Ny naoty, ny rakitra, ny rakitra ampiana ary ny fikirana dia tehirizina eo an-toerana, ao amin'ny fitahirizana manokana an'ny rindrankajy.",
    'privacy_encryption_title': "Fanafenana ny angona",
    'privacy_encryption_body':
        "Ny banky angona sy ny rakitra ampiana dia afenina ao amin'ny finday. Ny fanalahidy dia tehirizina ao amin'ny fitahirizana azo antoka an'ny rafitra ary tsy mivoaka mihitsy.",
    'privacy_crash_title': 'Tatitra momba ny olana (tsy voatery)',
    'privacy_crash_body':
        "Tsy mandeha raha tsy velona. Raha velonao ny « {option_bug_report} », dia alefa any amin'ny Sentry (Functional Software, Inc.) ny angona ara-teknika momba ny olana — ny hadisoana, ny dikan-teny, ny modely finday ary ny dikan-tenin'ny rafitra — mba ahafahana manamboatra azy. Tsy misy adiresy IP, tsy misy famantarana maharitra ary tsy misy votoatin'ny naoty alefa, ary tsy misy kaonty noforonina. Raha averinao ho tsy velona ny bokotra dia mijanona tsy mandeha intsony ny fandefasana.",
    'privacy_updates_title': 'Fanamarinana ny fanavaozana',
    'privacy_updates_body':
        "Rehefa manokatra ny efijery Momba ny ianao dia manontany ny store ny rindrankajy raha misy dikan-teny vaovao. Ny anaran'ny rindrankajy ihany no alefa — tsy misy kaonty, tsy misy famantarana, ary tsy misy tehirizina. Azo atao koa ny manamarina amin'ny tanana avy amin'io efijery io.",
    'privacy_tracking_title': 'Tsy misy fanarahana, tsy misy doka',
    'privacy_tracking_body':
        "Ny TanoNote dia tsy misy fandinihana fampiasana, tsy misy doka ary tsy misy mpanara-maso avy any ivelany; tsy mivarotra na mizara ny angonao izy. Tsy misy angonina raha tsy velonao ny tatitra momba ny olana.",
    'privacy_delete_title': 'Famafana ny angonao',
    'privacy_delete_body':
        "Afaka fafana ao amin'ny fikirana ny zavatra rehetra. Satria tsy misy tehirizina any aminay, dia ampy ny mamafa ny rindrankajy na ny angona: tsy misy fangatahana alefa, ary tsy misy dika mitovy any an-kafa.",
    'privacy_updated': 'Farany nohavaozina: Septambra 2026',
    'licenses': 'Lisansa',
    'license_disclaimer':
        "Ity dia nadika avy tamin'ny dikan-teny anglisy tany am-boalohany tamin'ny alalan'ny AI, nefa efa novakiana sy nohamarinin'olombelona. Na izany aza, mety mbola hisy ny hadisoana amin'ny fandikan-teny. Mifona mialoha izahay ary misaotra anareo amin'ny fahatakarana.",
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
