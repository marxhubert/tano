import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:tano/core/repositories/attachments_store.dart';

/// Resource limits are part of the v1 transfer contract, not ZIP metadata trust.
class ArchiveValidation {
  static const maxArchiveBytes = 64 * 1024 * 1024;
  static const maxExpandedBytes = 128 * 1024 * 1024;
  static const maxEntryBytes = 32 * 1024 * 1024;
  static const maxManifestBytes = 4 * 1024 * 1024;
  static const maxEntries = 2000;

  static Map<String, Uint8List> read(Uint8List bytes) {
    if (bytes.length > maxArchiveBytes) {
      throw const FormatException('Export too large');
    }
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    if (directory.fileHeaders.isEmpty ||
        directory.fileHeaders.length > maxEntries) {
      throw const FormatException('Invalid archive entry count');
    }
    final names = <String>{};
    var total = 0;
    // Validate every header before any decompression, including symlinks.
    for (final header in directory.fileHeaders) {
      final name = header.filename;
      if (!names.add(name) ||
          header.file?.filename != name ||
          (header.externalFileAttributes >> 16 & 0xf000) == 0xa000 ||
          header.generalPurposeBitFlag & 1 != 0 ||
          ![0, 8].contains(header.compressionMethod)) {
        throw const FormatException('Unsupported archive entry');
      }
      if (name == 'attachments/' && header.uncompressedSize == 0) continue;
      if (name != 'manifest.json') {
        if (!name.startsWith('attachments/')) {
          throw const FormatException('Unexpected archive path');
        }
        AttachmentsStore.validateName(name.substring('attachments/'.length));
      }
      final limit = name == 'manifest.json' ? maxManifestBytes : maxEntryBytes;
      total += header.uncompressedSize;
      if (header.uncompressedSize < 0 ||
          header.uncompressedSize > limit ||
          total > maxExpandedBytes) {
        throw const FormatException('Export too large');
      }
    }
    final files = <String, Uint8List>{};
    for (final header in directory.fileHeaders) {
      if (header.filename == 'attachments/') continue;
      final output = _BoundedOutput(header.uncompressedSize);
      header.file!.decompress(output);
      final content = output.getBytes();
      if (content.length != header.uncompressedSize ||
          getCrc32(content) != header.crc32) {
        throw const FormatException('Corrupted archive entry');
      }
      files[header.filename] = content;
    }
    return files;
  }
}

/// Enforces the declared size while inflating, even when ZIP metadata lies.
class _BoundedOutput extends OutputMemoryStream {
  _BoundedOutput(this.limit);
  final int limit;
  void _check(int count) {
    if (count < 0 || length + count > limit) {
      throw const FormatException('Archive expansion limit exceeded');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }
}
