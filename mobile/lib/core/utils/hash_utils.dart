import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class HashUtils {
  HashUtils._();

  static String sha256Hash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  static Future<String> sha256HashFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha256Hash(bytes);
  }

  static String sha256HashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
