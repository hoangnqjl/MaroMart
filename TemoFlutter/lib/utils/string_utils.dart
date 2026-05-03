import 'package:temo/utils/constants.dart';

class StringUtils {
  static String simplifyAddress(String? address) {
    if (address == null || address.isEmpty) return "";
    String result = address;
    // Danh sách các tiền tố cần loại bỏ
    final prefixes = [
      "Phường ",
      "Xã ",
      "Thành phố ",
      "Tỉnh ",
      "Quận ",
      "Huyện ",
      "phường ",
      "xã ",
      "thành phố ",
      "tỉnh ",
      "quận ",
      "huyện ",
    ];
    for (var prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length);
        break;
      }
    }
    return result;
  }

  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return "";

    // Handle cases where the URL might be prefixed with 'image:' or 'video:' (common in some backend responses)
    if (url.contains('http')) {
      final startIndex = url.indexOf('http');
      url = url.substring(startIndex);
    }
    
    // If it's a full URL
    if (url.startsWith('http')) {
      try {
        Uri uri = Uri.parse(url);
        String host = uri.host;
        
        // Only normalize if the host is an IP address (v4) or localhost
        bool isLocalHost = host == 'localhost' || host == '127.0.0.1';
        bool isIp = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host);
        
        if ((isIp || isLocalHost) && !url.startsWith(ApiConstants.baseUrl)) {
           // This is likely an old local server IP, so we normalize it to current baseUrl
           String path = uri.path;
           if (!path.startsWith('/')) path = '/$path';
           return "${ApiConstants.baseUrl}$path${uri.query.isNotEmpty ? '?${uri.query}' : ''}";
        }
        
        // If it's an external URL (Cloudinary, Unsplash, etc.), keep it exactly as is
        return url;
      } catch (e) {
        return url;
      }
    }
    
    // If it's a relative path
    String path = url;
    if (!path.startsWith('/')) path = '/$path';
    return "${ApiConstants.baseUrl}$path";
  }
}
