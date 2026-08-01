import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web HTML file picker
import 'dart:html' as html;

class SelectedFileInfo {
  final String name;
  final List<int> bytes;
  final int size;

  SelectedFileInfo({
    required this.name,
    required this.bytes,
    required this.size,
  });
}

class FilePickerHelper {
  /// Opens native OS / Browser File Explorer to select a file from user's local disk
  static Future<SelectedFileInfo?> pickFile({required String accept}) async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = accept; // e.g. '.pdf' or 'image/*'
      uploadInput.click();

      final completer = Completer<SelectedFileInfo?>();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          completer.complete(null);
          return;
        }

        final file = files.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        await reader.onLoadEnd.first;
        final bytes = (reader.result as List<int>).toList();

        completer.complete(SelectedFileInfo(
          name: file.name,
          bytes: bytes,
          size: file.size,
        ));
      });

      return completer.future;
    }

    return null;
  }
}
