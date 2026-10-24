import 'dart:io';
import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan gambar sampul artikel secara aman dan mulus.
/// Mendukung network URL, file lokal hasil ImagePicker, asset lokal, dan fallback placeholder.
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
    final isNetwork = imageUrl != null && imageUrl!.trim().startsWith('http');
    final isLocalFile = imageUrl != null &&
        !imageUrl!.trim().startsWith('http') &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.startsWith('/') || imageUrl!.contains(r':\') || imageUrl!.contains('/'));

    if (isNetwork) {
      imageWidget = Image.network(
        imageUrl!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (isLocalFile) {
      try {
        final file = File(imageUrl!.trim());
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
      color: placeholderColor ?? const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (width != null && width! < 60) ? 24 : 36,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
