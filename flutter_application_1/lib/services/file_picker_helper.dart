import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web HTML file picker
import 'dart:html' as html;

class SelectedFileInfo {
  final String name;
  final List<int> bytes;
  final int size;
  final int pageCount;

  SelectedFileInfo({
    required this.name,
    required this.bytes,
    required this.size,
    int? pageCount,
  }) : pageCount = pageCount ?? (name.toLowerCase().endsWith('.pdf') ? FilePickerHelper.getPdfPageCount(bytes) : 1);
}

class FilePickerHelper {
  /// Extracts total page count directly from PDF binary bytes
  static int getPdfPageCount(List<int> bytes) {
    try {
      final str = String.fromCharCodes(bytes);
      
      // Method 1: Look for /Count N in PDF objects catalog
      final countMatches = RegExp(r'/Count\s+(\d+)').allMatches(str);
      int maxCount = 0;
      for (final match in countMatches) {
        final countStr = match.group(1);
        if (countStr != null) {
          final count = int.tryParse(countStr) ?? 0;
          if (count > maxCount) maxCount = count;
        }
      }
      if (maxCount > 0) return maxCount;

      // Method 2: Count /Type /Page
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(str);
      if (pageMatches.isNotEmpty) {
        return pageMatches.length;
      }
    } catch (_) {}
    return 1;
  }

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
