import 'package:flutter/material.dart';
import '../Skeleton.dart';

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleSkeleton(size: 50),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 16, width: 150),
                const SizedBox(height: 10),
                const Skeleton(height: 14, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
