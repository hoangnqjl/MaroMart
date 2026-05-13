import 'package:flutter/material.dart';

/// Stub class to prevent compilation errors on non-web platforms.
class WebImageRegistry {
  static void registerView(String viewID, String imageUrl, BoxFit fit) {
    // Do nothing on mobile
  }

  static Widget buildWebView(String viewID, String imageUrl, double? width, double? height) {
    return const SizedBox.shrink();
  }
}
