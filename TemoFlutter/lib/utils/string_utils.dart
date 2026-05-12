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

    // 1. Loại bỏ các tiền tố 'image:' hoặc 'video:' và khoảng trắng
    String cleanUrl = url.replaceFirst('image:', '').replaceFirst('video:', '').trim();

    // 2. Nếu chứa một URL hoàn chỉnh (có http)
    if (cleanUrl.contains('://')) {
      try {
        // Trích xuất lấy phần URL thực sự (phòng trường hợp dính ký tự lạ)
        final uriMatch = RegExp(r'https?://[^\s/$.?#].[^\s]*').firstMatch(cleanUrl);
        if (uriMatch != null) {
          String fullUrl = uriMatch.group(0)!;
          Uri uri = Uri.parse(fullUrl);
          
          // Lấy phần path và query sau domain
          String pathAndQuery = uri.path;
          if (uri.query.isNotEmpty) pathAndQuery += '?${uri.query}';
          
          return _buildFinalUrl(pathAndQuery);
        }
      } catch (e) {
        // Nếu lỗi parse, giữ nguyên cleanUrl để xử lý tiếp ở bước 3
      }
    }
    
    // 3. Nếu là đường dẫn tương đối hoặc fallback từ bước 2
    return _buildFinalUrl(cleanUrl);
  }

  static String _buildFinalUrl(String path) {
    String baseUrl = ApiConstants.baseUrl;
    // Đảm bảo baseUrl không kết thúc bằng /
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Đảm bảo path bắt đầu bằng /
    String cleanPath = path;
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    
    // Loại bỏ tiền tố '/temo' cũ nếu bị dính từ database
    if (cleanPath.startsWith('/temo/')) {
      cleanPath = cleanPath.replaceFirst('/temo/', '/');
    }
    
    return "$baseUrl$cleanPath";
  }
}
