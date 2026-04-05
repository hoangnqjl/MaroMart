import 'package:flutter/material.dart';
import '../Skeleton.dart';

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleSkeleton(size: 44),
          const SizedBox(height: 10),
          const Skeleton(height: 10, width: 50),
        ],
      ),
    );
  }
}
