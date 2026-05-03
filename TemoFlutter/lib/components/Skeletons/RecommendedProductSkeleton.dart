import 'package:flutter/material.dart';
import '../Skeleton.dart';

class RecommendedProductSkeleton extends StatelessWidget {
  const RecommendedProductSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Placeholder
          const Skeleton(borderRadius: 30),
          
          // Content Overlay Placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(height: 24, width: 180, borderRadius: 12),
                    const SizedBox(height: 8),
                    const Skeleton(height: 18, width: 100, borderRadius: 8),
                  ],
                ),
                // Location Bar Placeholder
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const CircleSkeleton(size: 16),
                        const SizedBox(width: 8),
                        const Skeleton(height: 14, width: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
