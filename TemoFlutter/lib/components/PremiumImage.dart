import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/components/ModernLoader.dart';
// CONDITIONAL IMPORT: This is the magic that fixes the build error.
import 'web_image_stub.dart' if (dart.library.html) 'web_image_web.dart';

class PremiumImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth; // For mobile optimization
  final int? memCacheHeight;

  const PremiumImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError();
    }

    Widget image;
    
    if (kIsWeb) {
      // Use the image proxy for web to reduce bandwidth and lag
      final String optimizedUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=720&q=80&output=webp';
      
      image = Image.network(
        optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? _buildError(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
      );
    } else {
      // On Mobile, use CachedNetworkImage with cache constraints to "bóp" size to HD
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // MOBILE OPTIMIZATION: Limit disk cache size to HD (720p)
        maxWidthDiskCache: memCacheWidth ?? 720,
        maxHeightDiskCache: memCacheHeight ?? 720,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildError(),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    
    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      child: const Center(child: ModernLoader(size: 20)),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
