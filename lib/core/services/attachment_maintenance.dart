import 'package:tano/core/repositories/attachments_store.dart';

/// A complete snapshot, including trash and covers. Errors must propagate;
/// an incomplete snapshot is never an empty set of references.
abstract interface class AttachmentReferenceSource {
  Future<Set<String>> referencedAttachments();
}

/// Run only during bootstrap, before editors/imports can create new references.
class AttachmentMaintenance {
  AttachmentMaintenance({required this.source, required this.store});
  final AttachmentReferenceSource source;
  final AttachmentsStore store;

  Future<int> collectAtStartup() async {
    final referenced = await source.referencedAttachments();
    // Validate the complete snapshot before deleting even one file.
    for (final name in referenced) {
      AttachmentsStore.validateName(name);
    }
    return store.removeUnreferenced(referenced);
  }
}
