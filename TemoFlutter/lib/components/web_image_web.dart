import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

class WebImageRegistry {
  static void registerView(String viewID, String imageUrl, BoxFit fit) {
    final String optimizedUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=720&q=80&output=webp';
    
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      final html.ImageElement element = html.ImageElement()
        ..src = optimizedUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _getFitString(fit);
      
      element.setAttribute('loading', 'lazy');
      element.setAttribute('decoding', 'async');
      
      return element;
    });
  }

  static Widget buildWebView(String viewID, String imageUrl, double? width, double? height) {
    final String optimizedUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=720&q=80&output=webp';
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: HtmlElementView(
        viewType: viewID,
        key: ValueKey(optimizedUrl),
      ),
    );
  }

  static String _getFitString(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover: return 'cover';
      case BoxFit.contain: return 'contain';
      case BoxFit.fill: return 'fill';
      case BoxFit.fitWidth: return 'scale-down';
      case BoxFit.fitHeight: return 'scale-down';
      case BoxFit.none: return 'none';
      case BoxFit.scaleDown: return 'scale-down';
      default: return 'cover';
    }
  }
}
