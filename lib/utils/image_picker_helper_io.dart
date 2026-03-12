import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<String?> pickImageAsDataUrlImpl() async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final file = picked?.files.single;
  if (file == null) return null;

  var bytes = file.bytes;
  if (bytes == null && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null) return null;

  final mimeType = _mimeTypeForExtension(file.extension);
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String _mimeTypeForExtension(String? extension) {
  switch ((extension ?? '').toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/png';
  }
}
