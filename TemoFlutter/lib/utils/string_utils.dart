import 'package:temo/utils/constants.dart';
import 'package:flutter/foundation.dart';

class StringUtils {
  static String simplifyAddress(String? address) {
    if (address == null || address.isEmpty) return "";
    String result = address;
    final prefixes = [
      "Phường ", "Xã ", "Thành phố ", "Tỉnh ", "Quận ", "Huyện ",
      "phường ", "xã ", "thành phố ", "tỉnh ", "quận ", "huyện ",
    ];
    for (var prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length);
        break;
      }
    }
    return result;
  }

  /// Chuẩn hóa URL thành đường dẫn tuyệt đối chuẩn
  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('assets/') || url.startsWith('blob:')) return url;
    
    String cleanUrl = url.replaceFirst('image:', '').replaceFirst('video:', '').trim();

    // Fix: Nếu backend trả về URL chứa localhost/127.0.0.1 (thường do cấu hình server chưa chuẩn),
    // ta ép nó về baseUrl chuẩn của ứng dụng để đảm bảo nạp được ảnh.
    if (cleanUrl.contains('://localhost') || cleanUrl.contains('://127.0.0.1')) {
      try {
        final uri = Uri.parse(cleanUrl);
        String pathWithQuery = uri.path;
        if (uri.hasQuery) {
          pathWithQuery += "?${uri.query}";
        }
        return _buildFinalUrl(pathWithQuery);
      } catch (e) {
        // Fallback if parsing fails
      }
    }

    if (cleanUrl.contains('://')) return cleanUrl;
    
    return _buildFinalUrl(cleanUrl);
  }

  /// Bọc Proxy cho Web để vượt CORS và nén dung lượng
  static String proxify(String url, {int? width}) {
    if (!kIsWeb) return url;
    if (url.isEmpty || url.startsWith('assets/') || url.startsWith('blob:')) return url;
    if (url.contains('wsrv.nl')) return url; // Đã có proxy

    int w = width ?? 720;
    return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=$w&q=80&output=webp";
  }

  static String _buildFinalUrl(String path) {
    String baseUrl = ApiConstants.baseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    String cleanPath = path;
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    
    if (cleanPath.startsWith('/temo/')) {
      cleanPath = cleanPath.replaceFirst('/temo/', '/');
    }
    
    return "$baseUrl$cleanPath";
  }
  static String getInitials(String name) {
    if (name.trim().isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }
}
