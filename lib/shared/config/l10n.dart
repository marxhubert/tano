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
    'all_docs': 'All docs',
    'filter_all': 'All',
    'filter_notes': 'Notes',
    'filter_tasks': 'Tasks',
    'docs': 'docs',
    'doc': 'doc',
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
    'trash_empty': 'Empty trash',
    'note': 'note',
    'notes': 'notes',
    'search': 'Search',
    'all_notes_selected': 'All {count} notes are selected',
    'notes_selected': '{count}/{total} notes selected',
    'single_note_selected': '{count} single note selected',
    'single_task_selected': '{count} single task selected',
    'single_doc_selected': '{count} single doc selected',
    'tasks_selected': '{count}/{total} tasks selected',
    'all_tasks_selected': 'All {count} tasks are selected',
    'docs_selected': '{count}/{total} docs selected',
    'all_docs_selected': 'All {count} docs are selected',
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
    'no_note_found': 'No item found',
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
    'export_data': 'Export data',
    'import_data': 'Import data',
    'export_action': 'Export',
    'export_encrypt': 'Encrypt the export',
    'export_password': 'Password',
    'export_password_hint': '8 characters minimum',
    'password_too_short': 'The password must be at least 8 characters.',
    'export_locked_required': 'Locked notes require an encrypted export.',
    'export_failed': 'Export failed',
    'export_done': 'Export saved.',
    'import_password_title': 'Encrypted export',
    'import_password_message': 'Enter the password of this export.',
    'import_failed': 'Import failed',
    'import_too_large': 'This export exceeds the 64 MiB limit.',
    'import_done':
        '{added} notes added, {folders} folders, {skipped} skipped, {unlocked} unlocked.',
    'import_clear_warning':
        'Cleartext exports are not protected. Keep them safe.',
    'quit_app': 'Quit',
    'privacy_screen_locked':
        "This content is locked. Authenticate to continue.",
    'storage_recovery_message':
        "Storage is temporarily unavailable. Unlock your device, check its free space, then retry. Your existing data will not be reset.",
    'load_error_title': 'Unable to load your notes',
    'load_error_message':
        'Something went wrong while opening the app. You can try again.',
    'cancel': 'Cancel',
    'ok': 'OK',
    'back': 'Back',
    'no_title': 'No title',
    'no_data': 'Nothing yet',
    'empty': 'Empty',
    'edit_note': 'Edit note',
    'completed_tasks': 'Completed tasks',
    'description_limit': 'The description is limited to 500 characters.',
    'add_description': 'Add description',
    'description': 'Description',
    'find_in_tasks': 'Find in tasks',
    'add_task': 'Add task list',
    'edit_task': 'Edit task list',
    'tasks': 'tasks',
    'task': 'task',
    'add_task_item': 'Add a task',
    'add_note': 'Add note',
    'find_in_note': 'Find in note',
    'chars': 'chars',
    'folders_group': 'Folders',
    'notes_group': 'Docs',
    'title': 'Title',
    'content': 'Content',
    'important': 'Important',
    'about_description':
        'TanoNote is a minimal, secure, and fast note-taking app designed to keep your ideas organized and your mind focused. It prioritizes privacy by keeping all your data exclusively on your device.',
    'about_cta':
        'Help us grow and improve TanoNote! Your support allows us to keep the app free and private for everyone. Consider taking action below:',
    'about_premium': 'Get Premium version',
    'premium_projects': "Projects",
    'premium_sharing': "Sharing",
    'premium_collaboration': "Collaboration",
    'premium_intro':
        "Premium will include projects, sharing and collaboration.",
    'premium_unavailable':
        "These features are in development. Purchases are not available yet.",
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
        "Send optional crash diagnostics without note content or a persistent user identifier. You can withdraw consent at any time.",
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
    'menu_left_side': 'Left side',
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
    // Privacy policy. The canonical text lives in docs/privacy.md.
    'privacy': 'Privacy policy',
    'privacy_intro':
        "TanoNote requires no account. Your notes and folders are stored locally. Optional diagnostics and update checks use external services.",
    'privacy_local_title': 'Data stored on your device',
    'privacy_local_body':
        'Your notes, folders, attachments and preferences are saved locally, in the private storage of the app.',
    'privacy_encryption_title': 'Encryption at rest',
    'privacy_encryption_body':
        'The database and the attachments are encrypted on the device. The key is kept in the secure storage of the system and never leaves it.',
    'privacy_crash_title': 'Crash reports (optional)',
    'privacy_crash_body':
        "Off by default. With “{option_bug_report}” enabled, configured builds send filtered exception types, stack symbols, app version, device model, OS version and configured device region (not precise location) to Sentry (Functional Software, Inc.). Note content, free-form error messages and persistent user identifiers are excluded. Network services necessarily receive your IP address; its retention must be restricted by the service configuration. Withdrawing consent stops new captures; already queued or transmitted reports may remain.",
    'privacy_updates_title': 'Update check',
    'privacy_updates_body':
        "When you request an update check from About, the app contacts the App Store or Google Play. No note content is sent. The store processes the network metadata of this request.",
    'privacy_tracking_title': 'No tracking, no ads',
    'privacy_tracking_body':
        'TanoNote contains no usage analytics, no advertising and no third-party tracker, and never sells or shares your data. Nothing is collected until you turn the crash reports on.',
    'privacy_delete_title': 'Deleting your data',
    'privacy_delete_body':
        "Settings can delete local app data. This does not erase exported files, copies held by other applications or diagnostics already sent. Known pre-release plaintext backups are discarded when local storage opens.",
    'privacy_updated': 'Last updated: September {year}',
    'licenses': 'Licenses',
    'license_disclaimer':
        'This has been translated from the original English version by an AI, then reviewed and verified by a human. However, translation errors may still occur. We apologize in advance and thank you for your understanding.',
    'license_view_original': 'View original version',
    'lang_en': 'ENGLISH',
    'lang_fr': 'FRENCH',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Delete photo',
    if (!kReleaseMode) 'developer_reset': 'Developer reset',
    if (!kReleaseMode)
      'developer_reset_failed':
          'Reset could not finish. Some data may already have been replaced. Retry to reload all demo data.',
    // Labs: the developer surface, debug and development builds only.
    if (!kReleaseMode) 'labs': 'Labs',
    if (!kReleaseMode)
      'labs_hint':
          'Developer tools. Debug and development builds only, never in a release.',
    if (!kReleaseMode) 'labs_sentry_test': 'Send a test error',
    if (!kReleaseMode) 'labs_sentry_sent': 'Test error sent to Sentry.',
    if (!kReleaseMode)
      'labs_sentry_unavailable':
          'Crash reports are off. Turn them on before sending a test.',
    // Introduction
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_start': 'Get started',
    'onboarding_title_1': 'Every note in one place',
    'onboarding_body_1':
        'Write on the go. TanoNote works with no connection and keeps everything encrypted on your phone. No account, no tracking.',
    'onboarding_title_2': 'Lock what matters',
    'onboarding_body_2':
        'Secure a note with your code or your fingerprint: it opens only once you are recognised.',
    'onboarding_title_3': 'In order, with a way back',
    'onboarding_body_3':
        'Sort your notes into folders, and find everything you deleted in the trash — with one tap to undo.',
    'onboarding_replay': 'Replay the introduction',
    // Feedback and text
    'menu_feedback': 'Feedback and text',
    'text_size_small': 'Small',
    'text_size_normal': 'Normal',
    'text_size_large': 'Large',
    'text_size_extra_large': 'Larger',
    'feedback_haptics': 'Haptic feedback',
    'feedback_sound': 'Sound',
    'moved_to': 'moved to {folder}',
    'moved_home': 'moved back to Home',
    'moved': 'moved',
    'note_locked': 'Note locked',
    'note_unlocked': 'Note unlocked',
    'folder_locked': 'Folder locked',
    'folder_unlocked': 'Folder unlocked',
    // Search
    'search_history': 'Recent',
  };

  static const Map<String, String> _fr = <String, String>{
    // Home
    'all_docs': 'Tous les docs',
    'filter_all': 'Tous',
    'filter_notes': 'Notes',
    'filter_tasks': 'Tâches',
    'docs': 'docs',
    'doc': 'doc',
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
    'trash_empty': 'Corbeille vide',
    'note': 'note',
    'notes': 'notes',
    'search': 'Rechercher',
    'all_notes_selected': 'Toutes les {count} notes sont sélectionnées',
    'notes_selected': '{count}/{total} notes sélectionnées',
    'single_note_selected': '{count} seule note sélectionnée',
    'single_task_selected': '{count} seule tâche sélectionnée',
    'single_doc_selected': '{count} seul doc sélectionné',
    'tasks_selected': '{count}/{total} tâches sélectionnées',
    'all_tasks_selected': 'Toutes les {count} tâches sont sélectionnées',
    'docs_selected': '{count}/{total} docs sélectionnés',
    'all_docs_selected': 'Tous les {count} docs sont sélectionnés',
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
    'no_note_found': 'Aucun élément trouvé',
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
    'export_data': 'Exporter les données',
    'import_data': 'Importer des données',
    'export_action': 'Exporter',
    'export_encrypt': "Chiffrer l'export",
    'export_password': 'Mot de passe',
    'export_password_hint': '8 caractères minimum',
    'password_too_short': 'Le mot de passe doit faire au moins 8 caractères.',
    'export_locked_required':
        'Les notes verrouillées exigent un export chiffré.',
    'export_failed': "Échec de l'export",
    'export_done': 'Export enregistré.',
    'import_password_title': 'Export chiffré',
    'import_password_message': "Saisissez le mot de passe de cet export.",
    'import_failed': "Échec de l'import",
    'import_too_large': "Cet export dépasse la limite de 64 Mio.",
    'import_done':
        '{added} notes ajoutées, {folders} dossiers, {skipped} ignorées, {unlocked} déverrouillées.',
    'import_clear_warning':
        "Les exports en clair ne sont pas protégés. Gardez-les en sécurité.",
    'quit_app': 'Quitter',
    'privacy_screen_locked':
        "Ce contenu est verrouillé. Authentifiez-vous pour continuer.",
    'storage_recovery_message':
        "Le stockage est indisponible. Déverrouillez l’appareil, vérifiez l’espace libre, puis réessayez. Vos données existantes ne seront pas réinitialisées.",
    'load_error_title': 'Impossible de charger vos notes',
    'load_error_message':
        "Une erreur est survenue à l'ouverture de l'application. Vous pouvez réessayer.",
    'cancel': 'Annuler',
    'ok': 'OK',
    'back': 'Retour',
    'no_title': 'Sans titre',
    'no_data': "Rien pour l'instant",
    'empty': 'Vide',
    'edit_note': 'Modifier la note',
    'completed_tasks': 'Tâches achevées',
    'description_limit': 'La description est limitée à 500 caractères.',
    'add_description': 'Ajouter une description',
    'description': 'Description',
    'find_in_tasks': 'Rechercher dans les tâches',
    'add_task': 'Ajouter une liste de tâches',
    'edit_task': 'Modifier la liste de tâches',
    'tasks': 'tâches',
    'task': 'tâche',
    'add_task_item': 'Ajouter une tâche',
    'add_note': 'Ajouter une note',
    'find_in_note': 'Rechercher dans la note',
    'chars': 'caractères',
    'folders_group': 'Dossiers',
    'notes_group': 'Docs',
    'title': 'Titre',
    'content': 'Contenu',
    'important': "Important",
    'about_description':
        "TanoNote est une application de prise de notes minimaliste, sécurisée et rapide, conçue pour organiser vos idées tout en restant concentré. Elle privilégie votre vie privée en conservant toutes vos données exclusivement sur votre appareil.",
    'about_cta':
        "Aidez-nous à faire grandir et améliorer TanoNote ! Votre soutien nous permet de garder l'application gratuite et privée pour tous. Voici comment vous pouvez nous aider :",
    'about_premium': "Passer à la version Premium",
    'premium_projects': "Projets",
    'premium_sharing': "Partage",
    'premium_collaboration': "Collaboration",
    'premium_intro':
        "Premium comprendra les projets, le partage et la collaboration.",
    'premium_unavailable':
        "Ces fonctionnalités sont en développement. Les achats ne sont pas encore disponibles.",
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
        "Envoyez des diagnostics facultatifs sans contenu de note ni identifiant persistant d’usager. Vous pouvez retirer votre consentement à tout moment.",
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
    'menu_left_side': 'À gauche',
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
    // Police de confidentialité. Le texte de référence vit dans docs/privacy.md.
    'privacy': 'Confidentialité',
    'privacy_intro':
        "TanoNote ne nécessite aucun compte. Vos notes et dossiers sont stockés localement. Les diagnostics facultatifs et la vérification des mises à jour utilisent des services externes.",
    'privacy_local_title': 'Données stockées sur votre appareil',
    'privacy_local_body':
        "Vos notes, dossiers, pièces jointes et préférences sont enregistrés localement, dans l'espace privé de l'application.",
    'privacy_encryption_title': 'Chiffrement au repos',
    'privacy_encryption_body':
        "La base de données et les pièces jointes sont chiffrées sur l'appareil. La clé est conservée dans le stockage sécurisé du système et n'en sort jamais.",
    'privacy_crash_title': 'Rapports de crash (facultatif)',
    'privacy_crash_body':
        "Désactivés par défaut. Avec « {option_bug_report} », les versions configurées envoient à Sentry (Functional Software, Inc.) des types d’erreurs, symboles de pile filtrés, version de l’app, modèle de l’appareil, version de l’OS et région configurée (pas de localisation précise). Le contenu des notes, les messages d’erreur libres et les identifiants persistants d’usagers sont exclus. Les services réseau reçoivent nécessairement votre adresse IP ; sa conservation doit être limitée par leur configuration. Le retrait du consentement arrête les nouvelles captures ; des rapports déjà en attente ou transmis peuvent subsister.",
    'privacy_updates_title': 'Vérification des mises à jour',
    'privacy_updates_body':
        "Lorsque vous demandez une vérification depuis À propos, l’app contacte l’App Store ou Google Play. Aucun contenu de note n’est transmis. Le store traite les métadonnées réseau de cette requête.",
    'privacy_tracking_title': 'Aucun pistage, aucune publicité',
    'privacy_tracking_body':
        "TanoNote ne contient ni analyse d'usage, ni publicité, ni traceur tiers, et ne vend ni ne partage vos données. Rien n'est collecté tant que vous n'activez pas les rapports de crash.",
    'privacy_delete_title': 'Supprimer vos données',
    'privacy_delete_body':
        "Les paramètres permettent de supprimer les données locales de l’app. Cela n’efface pas les exports, les copies détenues par d’autres applications ni les diagnostics déjà envoyés. Les anciennes sauvegardes de test en clair sont supprimées à l’ouverture du stockage local.",
    'privacy_updated': 'Dernière mise à jour : septembre {year}',
    'licenses': 'Licences',
    'license_disclaimer':
        "Ceci a été traduit de la version originale anglaise par une IA, puis relu et vérifié par un humain. Toutefois, des erreurs de traduction peuvent encore subsister. Nous nous en excusons par avance et vous remercions de votre compréhension.",
    'license_view_original': "Voir la version originale",
    'lang_en': 'ANGLAIS',
    'lang_fr': 'FRANÇAIS',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Supprimer la photo',
    if (!kReleaseMode) 'developer_reset': 'Réinitialisation développeur',
    if (!kReleaseMode)
      'developer_reset_failed':
          'La réinitialisation a échoué. Certaines données ont peut-être déjà été remplacées. Réessayez pour recharger toutes les données de démonstration.',
    // Labos : la surface développeur, réservée aux versions debug et dev.
    if (!kReleaseMode) 'labs': 'Labos',
    if (!kReleaseMode)
      'labs_hint':
          'Outils développeur. Réservés aux versions debug et développement, jamais à une version publiée.',
    if (!kReleaseMode) 'labs_sentry_test': 'Envoyer une erreur de test',
    if (!kReleaseMode) 'labs_sentry_sent': 'Erreur de test envoyée à Sentry.',
    if (!kReleaseMode)
      'labs_sentry_unavailable':
          'Les rapports de crash sont désactivés. Activez-les avant d’envoyer un test.',
    // Introduction
    'onboarding_skip': 'Passer',
    'onboarding_next': 'Suivant',
    'onboarding_start': 'Commencer',
    'onboarding_title_1': 'Toutes vos notes au même endroit',
    'onboarding_body_1':
        'Écrivez où que vous soyez. TanoNote fonctionne sans connexion et garde tout chiffré sur votre téléphone. Aucun compte, aucun suivi.',
    'onboarding_title_2': 'Verrouillez ce qui compte',
    'onboarding_body_2':
        "Protégez une note par code ou par empreinte : elle ne s'ouvre qu'après vérification.",
    'onboarding_title_3': "De l'ordre, et un retour en arrière",
    'onboarding_body_3':
        'Classez vos notes dans des dossiers et retrouvez dans la corbeille tout ce que vous supprimez — avec une annulation en un geste.',
    'onboarding_replay': "Revoir l'introduction",
    // Retours et texte
    'menu_feedback': 'Retours et texte',
    'text_size_small': 'Petit',
    'text_size_normal': 'Normal',
    'text_size_large': 'Grand',
    'text_size_extra_large': 'Plus grand',
    'feedback_haptics': 'Retour haptique',
    'feedback_sound': 'Son',
    'moved_to': 'déplacé(e) vers {folder}',
    'moved_home': "ramené(e) à l'accueil",
    'moved': 'déplacé(e)',
    'note_locked': 'Note verrouillée',
    'note_unlocked': 'Note déverrouillée',
    'folder_locked': 'Dossier verrouillé',
    'folder_unlocked': 'Dossier déverrouillé',
    // Recherche
    'search_history': 'Récentes',
  };

  static const Map<String, String> _mg = <String, String>{
    // Home
    'all_docs': 'Rakitra rehetra',
    'filter_all': 'Rehetra',
    'filter_notes': 'Naoty',
    'filter_tasks': 'Asa',
    'docs': 'rakitra',
    'doc': 'rakitra',
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
    'trash_empty': 'Foana ny fako',
    'note': 'naoty',
    'notes': 'naoty',
    'search': 'Karohy',
    'all_notes_selected': 'Voafantina daholo ny naoty {count}',
    'notes_selected': 'Naoty {count}/{total} voafantina',
    'single_note_selected': 'Naoty {count} voafantina',
    'single_task_selected': 'Asa {count} voafantina',
    'single_doc_selected': 'Rakitra {count} voafantina',
    'tasks_selected': 'Asa {count}/{total} voafantina',
    'all_tasks_selected': 'Voafantina daholo ny asa {count}',
    'docs_selected': 'Rakitra {count}/{total} voafantina',
    'all_docs_selected': 'Voafantina daholo ny rakitra {count}',
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
    'no_note_found': 'Tsy nisy zavatra hita',
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
    'export_data': 'Avoaka ny angona',
    'import_data': 'Hampiditra angona',
    'export_action': 'Avoaka',
    'export_encrypt': 'Hidio ny fanondranana',
    'export_password': 'Teny miafina',
    'export_password_hint': '8 litera farafahakeliny',
    'password_too_short': 'Tokony 8 litera Farafahakeliny ny teny miafina.',
    'export_locked_required': 'Mila fanondranana voahidy ny naoty voahidy.',
    'export_failed': 'Tsy nahomby ny fanondranana',
    'export_done': 'Voatahiry ny fanondranana.',
    'import_password_title': 'Fanondranana voahidy',
    'import_password_message':
        'Ampidiro ny teny miafina amin\'ity fanondranana ity.',
    'import_failed': 'Tsy nahomby ny fampidirana',
    'import_too_large': 'Mihoatra ny fetra 64 MiB ity rakitra ity.',
    'import_done':
        '{added} naoty nampidirina, {folders} lahatahiry, {skipped} nolavina, {unlocked} navahana.',
    'import_clear_warning':
        'Tsy voaaro ny fanondranana mazava. Tano tsara izy ireo.',
    'quit_app': 'Hiala',
    'privacy_screen_locked':
        "Voahidy ity votoaty ity. Hamarino ny maha-ianao anao vao manohy.",
    'storage_recovery_message':
        "Tsy azo ampiasaina ny fitahirizana. Vohay ny fitaovana, jereo ny toerana malalaka, ary andramo indray. Tsy hofafana ny angonao.",
    'load_error_title': 'Tsy afaka naka ny naoty',
    'load_error_message':
        'Nisy olana teo am-panokafana ny rindranasa. Afaka manandrana indray ianao.',
    'cancel': 'Atsaharo',
    'ok': 'OK',
    'back': 'Hiverina',
    'no_title': 'Tsy misy lohateny',
    'no_data': 'Mbola tsy misy',
    'empty': 'Foana',
    'edit_note': 'Hanova naoty',
    'completed_tasks': 'Asa vita',
    'description_limit': 'Tarehintsoratra 500 ihany ny fanazavana.',
    'add_description': 'Hanampy fanazavana',
    'description': 'Fanazavana',
    'find_in_tasks': 'Hikaroka ao amin’ny asa',
    'add_task': 'Hanampy lisitry ny asa',
    'edit_task': 'Hanova lisitry ny asa',
    'tasks': 'asa',
    'task': 'asa',
    'add_task_item': 'Hanampy asa',
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
    'premium_projects': "Tetikasa",
    'premium_sharing': "Fizarana",
    'premium_collaboration': "Fiaraha-miasa",
    'premium_intro':
        "Tafiditra ao amin’ny Premium ny tetikasa, ny fizarana ary ny fiaraha-miasa.",
    'premium_unavailable':
        "Mbola eo am-pamolavolana ireo fiasa ireo. Tsy mbola misy ny fividianana.",
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
        "Alefaso raha tianao ny tatitra ara-teknika tsy misy votoatin’ny naoty na famantarana maharitra ny mpampiasa. Azonao esorina amin’ny fotoana rehetra ny fanekenao.",
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
    'menu_left_side': 'Ankavia',
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
    // Politikan'ny tsiambaratelo. Ny lahatsoratra fototra dia ao amin'ny docs/privacy.md.
    'privacy': 'Tsiambaratelo',
    'privacy_intro':
        "Tsy mila kaonty ny TanoNote. Tehirizina eo an-toerana ny naoty sy ny lahatahiry. Mampiasa tolotra ivelany ny tatitra tsy voatery sy ny fanamarinana fanavaozana.",
    'privacy_local_title': "Angona tehirizina ao amin'ny findainao",
    'privacy_local_body':
        "Ny naoty, ny rakitra, ny rakitra ampiana ary ny fikirana dia tehirizina eo an-toerana, ao amin'ny fitahirizana manokana an'ny rindrankajy.",
    'privacy_encryption_title': "Fanafenana ny angona",
    'privacy_encryption_body':
        "Ny banky angona sy ny rakitra ampiana dia afenina ao amin'ny finday. Ny fanalahidy dia tehirizina ao amin'ny fitahirizana azo antoka an'ny rafitra ary tsy mivoaka mihitsy.",
    'privacy_crash_title': 'Tatitra momba ny olana (tsy voatery)',
    'privacy_crash_body':
        "Tsy mandeha raha tsy manaiky ianao. Raha velomina ny « {option_bug_report} », dia afaka mandefa karazana hadisoana, marika ara-teknika voasivana, dikan-tenin’ny app, modelin’ny fitaovana, dikan-tenin’ny OS ary faritra voafidy (fa tsy toerana marina) any amin’ny Sentry (Functional Software, Inc.) ny app voakirakira amin’izany. Tsy tafiditra ny votoatin’ny naoty, ny hafatra malalaka na ny famantarana maharitra ny mpampiasa. Hitan’ny tolotra tambajotra ny adiresy IP; mila ferana amin’ny fikirany ny fitahirizana azy. Mijanona ny fanangonana vaovao rehefa esorina ny fanekena, fa mety mbola hisy tatitra efa nalefa na miandry.",
    'privacy_updates_title': 'Fanamarinana ny fanavaozana',
    'privacy_updates_body':
        "Rehefa mangataka fanamarinana ao amin’ny Momba ny ianao dia mifandray amin’ny App Store na Google Play ny app. Tsy alefa ny votoatin’ny naoty. Ny store no mikarakara ny metadata momba ilay fifandraisana.",
    'privacy_tracking_title': 'Tsy misy fanarahana, tsy misy doka',
    'privacy_tracking_body':
        "Ny TanoNote dia tsy misy fandinihana fampiasana, tsy misy doka ary tsy misy mpanara-maso avy any ivelany; tsy mivarotra na mizara ny angonao izy. Tsy misy angonina raha tsy velonao ny tatitra momba ny olana.",
    'privacy_delete_title': 'Famafana ny angonao',
    'privacy_delete_body':
        "Afaka mamafa ny angona eo an-toerana ao amin’ny fikirana ianao. Tsy mamafa ny rakitra naondrana, ny kopia any amin’ny app hafa na ny tatitra efa nalefa izany. Fafana rehefa misokatra ny fitahirizana ireo tahiry fitsapana tranainy tsy voafina.",
    'privacy_updated': 'Farany nohavaozina: Septambra {year}',
    'licenses': 'Lisansa',
    'license_disclaimer':
        "Ity dia nadika avy tamin'ny dikan-teny anglisy tany am-boalohany tamin'ny alalan'ny AI, nefa efa novakiana sy nohamarinin'olombelona. Na izany aza, mety mbola hisy ny hadisoana amin'ny fandikan-teny. Mifona mialoha izahay ary misaotra anareo amin'ny fahatakarana.",
    'license_view_original': "Hijery ny dikan-teny tany am-boalohany",
    'lang_en': 'ANGLISY',
    'lang_fr': 'FRANTSAY',
    'lang_mg': 'MALAGASY',
    'delete_photo': 'Hamafa ny sary',
    if (!kReleaseMode) 'developer_reset': 'Fanavaozana ho an\'ny mpamorona',
    if (!kReleaseMode)
      'developer_reset_failed':
          'Tsy vita ny famerenana. Mety efa niova ny angona sasany. Andramo indray hampidirana ny angona andrana rehetra.',
    // Laboratoara: ny sehatra ho an'ny mpamorona, amin'ny kinova debug sy dev.
    if (!kReleaseMode) 'labs': 'Laboratoara',
    if (!kReleaseMode)
      'labs_hint':
          "Fitaovana ho an'ny mpamorona. Amin'ny kinova debug sy fampandrosoana ihany, tsy amin'ny kinova avoaka.",
    if (!kReleaseMode) 'labs_sentry_test': 'Alefaso ny hadisoana fanandramana',
    if (!kReleaseMode)
      'labs_sentry_sent':
          "Nalefa tany amin'ny Sentry ny hadisoana fanandramana.",
    if (!kReleaseMode)
      'labs_sentry_unavailable':
          'Tsy mandeha ny tatitra momba ny olana. Velomy aloha vao mandefa fanandramana.',
    // Fampidirana
    'onboarding_skip': 'Hitsambikina',
    'onboarding_next': 'Manaraka',
    'onboarding_start': 'Hanomboka',
    'onboarding_title_1': "Ny naotinao rehetra amin'ny toerana iray",
    'onboarding_body_1':
        "Manorata na aiza na aiza ianao. Miasa tsy misy fifandraisana ny TanoNote ary mitazona ny zava-drehetra voaaro ao amin'ny findainao. Tsy misy kaonty, tsy misy fanaraha-maso.",
    'onboarding_title_2': 'Hidio ny tena zava-dehibe',
    'onboarding_body_2':
        "Arovy amin'ny kaody na ny dian-tanana ny naoty iray: tsy misokatra izy raha tsy efa voamarina ianao.",
    'onboarding_title_3': 'Fandaminana sy fiverenana',
    'onboarding_body_3':
        "Alamino ao anaty rakitra ny naotinao ary hita ao amin'ny fitoeram-pako izay rehetra voafafa — misy fanafoanana amin'ny tsindry iray.",
    'onboarding_replay': 'Avereno jerena ny fanazavana',
    // Famaliana sy lahatsoratra
    'menu_feedback': 'Famaliana sy lahatsoratra',
    'text_size_small': 'Kely',
    'text_size_normal': 'Antonony',
    'text_size_large': 'Lehibe',
    'text_size_extra_large': 'Lehibe kokoa',
    'feedback_haptics': 'Fihovitrovitra',
    'feedback_sound': 'Feo',
    'moved_to': "nafindra tany amin'ny {folder}",
    'moved_home': "naverina tany amin'ny fandraisana",
    'moved': 'nafindra',
    'note_locked': 'Voahidy ny naoty',
    'note_unlocked': 'Novahana ny naoty',
    'folder_locked': 'Voahidy ny rakitra',
    'folder_unlocked': 'Novahana ny rakitra',
    // Fikarohana
    'search_history': 'Teo aloha',
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
