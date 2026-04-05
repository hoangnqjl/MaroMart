import 'package:flutter/material.dart';
import '../Skeleton.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 173,
      height: 305,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section Placeholder
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Skeleton(borderRadius: 25),
            ),
          ),
          
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  // Title Placeholder
                  const Skeleton(height: 18, width: 120),
                  const SizedBox(height: 8),
                  
                  // Location Placeholder
                  Row(
                    children: [
                      const CircleSkeleton(size: 14),
                      const SizedBox(width: 4),
                      const Skeleton(height: 14, width: 80),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Price and Button Placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Skeleton(height: 28, width: 80, borderRadius: 20),
                      const CircleSkeleton(size: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
