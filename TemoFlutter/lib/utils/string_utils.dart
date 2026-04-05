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
}
