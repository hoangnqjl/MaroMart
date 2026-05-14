import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/utils/string_utils.dart';
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

    if (imageUrl.startsWith('assets/')) {
      image = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? _buildError(),
      );
    } else if (kIsWeb) {
      // 1. If it's a blob: (Web Preview), use direct network image
      if (imageUrl.startsWith('blob:')) {
        image = Image.network(imageUrl, width: width, height: height, fit: fit, 
          errorBuilder: (context, error, stackTrace) => errorWidget ?? _buildError());
      } else {
        // TỐI ƯU WEB: Thay vì nạp ảnh HD, ta nhờ Proxy co ảnh về đúng kích thước hiển thị
        // Việc này giúp giảm RAM trình duyệt cực lớn.
        
        // 1. Tính toán chiều rộng mong muốn (mặc định 600 nếu không có)
        int w = 600; 
        if (memCacheWidth != null) {
          w = memCacheWidth!;
        } else if (width != null && width!.isFinite) {
          w = (width! * 2).toInt(); // Nhân 2 để sắc nét trên màn Retina
        }
        
        // 2. Giới hạn tối đa 1920 (HD) để tránh lãng phí, tối thiểu 100
        w = w.clamp(100, 1920);

        final String proxyUrl = StringUtils.proxify(imageUrl, width: w);
        
        image = Image.network(
          proxyUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, st) => errorWidget ?? _buildError(),
            );
          },
          // Trên Web, dùng placeholder đơn giản thay vì ModernLoader phức tạp để tránh lag
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ?? Container(color: Colors.grey[100]);
          },
        );
      }
    }
 else {
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

    return borderRadius > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: image,
          )
        : image;
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
