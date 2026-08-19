import 'package:tano/shared/config/l10n.dart';

/// Formats an ISO date string into a short, human-readable, localized date
/// (e.g. "12 Aug 2026" in English, "12 août 2026" in French).
///
/// Falls back to the raw string when parsing fails, so malformed data never
/// crashes the UI.
String formatNoteDate(String isoDate) {
  final DateTime? parsed = DateTime.tryParse(isoDate);
  if (parsed == null) {
    return isoDate;
  }

  final bool french = LocaleController.instance.language == 'fr';
  const List<String> enMonths = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const List<String> frMonths = <String>[
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  final String month = french
      ? frMonths[parsed.month - 1]
      : enMonths[parsed.month - 1];
  return '${parsed.day} $month ${parsed.year}';
}
