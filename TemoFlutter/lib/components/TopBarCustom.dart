import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'dart:ui';

class TopBarCustom extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const TopBarCustom({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button with Glassmorphism effect
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Icon(HeroiconsOutline.chevronLeft, color: Colors.black87, size: 24),
                ),
              ),
            ),
          ),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: Colors.black87,
            ),
          ),

          // Placeholder for balance at center-right
          const SizedBox(width: 44), 
        ],
      ),
    );
  }
}
