/// Shared identity and presentation contract. No Flutter or transport types.
/// A lock is a local UI gate, not a collaboration permission.
enum EntityKind { note, folder, task, project }

abstract interface class ContentEntity {
  String get id;
  EntityKind get kind;
  String get label;
  String get date;
  String get createdAt;
  String get updatedAt;
  String get category;
  bool get isImportant;
  bool get isLocked;
  bool get isDeleted;
  String? get deletedAt;
  String? get coverImage;
}

/// Distinguishes an omitted nullable copy field from explicitly clearing it.
const unchangedField = _UnchangedField();

class _UnchangedField {
  const _UnchangedField();
}

T? copiedNullable<T>(Object? value, T? previous) =>
    identical(value, unchangedField) ? previous : value as T?;

String normalizeCategory(String? value) =>
    value == null || value.isEmpty || value == 'none' || value == 'neutral'
    ? 'nuage'
    : value;
