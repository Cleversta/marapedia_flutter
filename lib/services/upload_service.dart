import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:convert';
import '../utils/constants.dart';

class UploadService {
  /// Compress + upload image to the existing /api/upload endpoint.
  /// Returns the public URL or throws.
  static Future<String> uploadImage(File file) async {
    final compressed = await _compress(file);
    final bytes = compressed ?? await file.readAsBytes();

    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}-'
        '${_randomStr()}.${ext.isEmpty ? 'jpg' : ext}';

    final request = http.MultipartRequest('POST', Uri.parse(AppConstants.uploadEndpoint));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(json['error'] ?? 'Upload failed');
    }
    return json['url'] as String;
  }

  static Future<List<int>?> _compress(File file) async {
    final ext = p.extension(file.path).toLowerCase();
    if (ext == '.gif') return null; // skip GIFs

    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1200,
      minHeight: 1200,
      quality: 82,
      keepExif: false,
    );
    return result;
  }

  static String _randomStr() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(6, (i) => chars.codeUnitAt((rand ~/ (i + 1)) % chars.length)),
    );
  }
}
