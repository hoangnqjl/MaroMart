import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/screens/Search/SearchResult.dart';
import 'package:maromart/app_router.dart';

class SearchItem extends StatefulWidget {
  const SearchItem({super.key});

  @override
  State<StatefulWidget> createState() => SearchItemState();
}

class SearchItemState extends State<SearchItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        smoothPush(
                          context,
                          SearchResultScreen(keyword: value.trim()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  HeroiconsOutline.microphone,
                  color: Colors.black54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}