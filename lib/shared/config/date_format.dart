/// Formats an ISO date string into a numeric day/month/year date
/// (`14/09/2026`), the format used on every card.
///
/// Falls back to the raw string when parsing fails, so malformed data never
/// crashes the UI.
String formatNoteDate(String isoDate) {
  final DateTime? parsed = DateTime.tryParse(isoDate);
  if (parsed == null) {
    return isoDate;
  }

  final String day = parsed.day.toString().padLeft(2, '0');
  final String month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}
