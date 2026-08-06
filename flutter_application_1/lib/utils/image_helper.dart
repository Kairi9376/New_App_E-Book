import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_config.dart';

class ImageHelper {
  /// Normalizes image paths to full valid URLs
  static String normalizeUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }
    if (trimmed.startsWith('uploads/') || trimmed.startsWith('/uploads/')) {
      final cleanPath = trimmed.replaceAll(RegExp(r'^/?uploads/'), '');
      return '${ApiConfig.uploadsBaseUrl}/$cleanPath';
    }
    if (!trimmed.contains('/') && !trimmed.contains('\\')) {
      return '${ApiConfig.uploadsBaseUrl}/$trimmed';
    }
    return trimmed;
  }

  /// Builds a profile avatar widget that falls back to a clean initial text avatar if no image or error occurs
  static Widget buildAvatar(
    String? path, {
    required String firstName,
    double size = 40,
    Color? backgroundColor,
    Uint8List? bytes,
  }) {
    final url = normalizeUrl(path);
    final initial = firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : 'U';

    final defaultAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (url.isEmpty && (bytes == null || bytes.isEmpty)) return defaultAvatar;

    return ClipOval(
      child: buildImage(
        url,
        bytes: bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: defaultAvatar,
      ),
    );
  }

  /// Builds a robust image widget supporting Network, Asset, Memory (Uint8List), and File
  static Widget buildImage(
    String? path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Uint8List? bytes,
    Widget? placeholder,
  }) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, width: width, height: height, fit: fit);
    }

    final url = normalizeUrl(path);
    if (url.isEmpty) {
      return placeholder ?? _buildDefaultPlaceholder(width, height);
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _buildDefaultPlaceholder(width, height),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _buildDefaultPlaceholder(width, height),
      );
    }

    if (!kIsWeb) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(file, width: width, height: height, fit: fit);
        }
      } catch (_) {}
    }

    return placeholder ?? _buildDefaultPlaceholder(width, height);
  }

  static Widget _buildDefaultPlaceholder(double? width, double? height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/BookCover.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.blueGrey.shade200),
          ),
          Container(
            color: Colors.black.withOpacity(0.25),
          ),
          const Center(
            child: Icon(Icons.book_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  /// Opens an interactive full-screen image preview dialog with pinch/zoom & pan
  static void showPreviewModal(
    BuildContext context, {
    String? path,
    Uint8List? bytes,
    String? title,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.92),
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.5,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(16),
                child: buildImage(path, bytes: bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ),
            ),
            if (title != null && title.isNotEmpty)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
