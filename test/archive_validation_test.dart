import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/services/archive_validation.dart';

void main() {
  Uint8List zip(String name, {int mode = 0x1a4}) {
    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', '{}'));
    final file = ArchiveFile.string(name, 'payload')..mode = mode;
    archive.addFile(file);
    return ZipEncoder().encodeBytes(archive);
  }

  test(
    'rejects traversals, absolute paths and unknown entries before extraction',
    () {
      for (final name in [
        'attachments/../x',
        'attachments//tmp/x',
        r'attachments/..\x',
        'other.txt',
      ]) {
        expect(() => ArchiveValidation.read(zip(name)), throwsFormatException);
      }
    },
  );
  test('valid archives are checked for corruption', () {
    final bytes = zip('attachments/x.txt');
    final files = ArchiveValidation.read(bytes);
    expect(String.fromCharCodes(files['attachments/x.txt']!), 'payload');
    // Corrupt the central-directory CRC, without breaking the ZIP structure.
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < bytes.length - 20; i++) {
      if (data.getUint32(i, Endian.little) == 0x02014b50) {
        bytes[i + 16] ^= 1;
        break;
      }
    }
    expect(() => ArchiveValidation.read(bytes), throwsFormatException);
  });
  test('stops inflation when a header understates the expanded size', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', 'x' * 100000));
    final bytes = ZipEncoder().encodeBytes(archive);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < bytes.length - 28; i++) {
      final sig = data.getUint32(i, Endian.little);
      if (sig == 0x02014b50) data.setUint32(i + 24, 1, Endian.little);
      if (sig == 0x04034b50) data.setUint32(i + 22, 1, Endian.little);
    }
    expect(() => ArchiveValidation.read(bytes), throwsFormatException);
  });
}
