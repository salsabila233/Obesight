import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan gambar sampul artikel secara aman dan mulus.
/// Mendukung format Base64 (data:image), network URL, blob URL, file lokal (mobile/desktop),
/// asset lokal, dan fallback placeholder.
class ArticleThumbnailImage extends StatelessWidget {
  final String? imageUrl;
  final String? imageAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final IconData placeholderIcon;

  const ArticleThumbnailImage({
    super.key,
    this.imageUrl,
    this.imageAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.placeholderIcon = Icons.article_rounded,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final rawUrl = imageUrl?.trim() ?? '';
    final isDataUri = rawUrl.startsWith('data:image');
    final isNetworkOrBlob = rawUrl.startsWith('http') || rawUrl.startsWith('blob:');
    final isLocalFile = !kIsWeb &&
        !isDataUri &&
        !isNetworkOrBlob &&
        rawUrl.isNotEmpty &&
        (rawUrl.startsWith('/') || rawUrl.contains(r':\') || rawUrl.contains('/'));

    if (isDataUri) {
      try {
        final commaIdx = rawUrl.indexOf(',');
        final base64Data = commaIdx != -1 ? rawUrl.substring(commaIdx + 1) : rawUrl;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildAssetOrPlaceholder(),
        );
      } catch (_) {
        imageWidget = _buildAssetOrPlaceholder();
      }
    } else if (isNetworkOrBlob) {
      imageWidget = Image.network(
        rawUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildAssetOrPlaceholder(),
      );
    } else if (isLocalFile) {
      try {
        final file = File(rawUrl);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildAssetOrPlaceholder(),
          );
        } else {
          imageWidget = _buildAssetOrPlaceholder();
        }
      } catch (_) {
        imageWidget = _buildAssetOrPlaceholder();
      }
    } else {
      imageWidget = _buildAssetOrPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(
          width: width,
          height: height,
          child: imageWidget,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildAssetOrPlaceholder() {
    if (imageAsset != null && imageAsset!.trim().isNotEmpty) {
      return Image.asset(
        imageAsset!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? const Color(0xFFE8F5EF),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (width != null && height != null) ? (width! * 0.35).clamp(20.0, 48.0) : 32.0,
          color: const Color(0xFF388E6B).withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
