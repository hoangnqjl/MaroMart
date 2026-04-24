import 'package:flutter/material.dart';
import '../Skeleton.dart';

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery Area Placeholder
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              margin: const EdgeInsets.fromLTRB(16, 120, 16, 0),
              child: const Skeleton(borderRadius: 40),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Title and Price Placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Skeleton(height: 24, width: 180),
                      const Skeleton(height: 24, width: 80),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags Placeholder
                  Row(
                    children: List.generate(3, (index) => const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Skeleton(height: 30, width: 80, borderRadius: 15),
                    )),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description Label
                  const Skeleton(height: 20, width: 100),
                  const SizedBox(height: 12),
                  // Description Body
                  Column(
                    children: List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Skeleton(height: 14, width: index == 3 ? 150 : double.infinity),
                    )),
                  ),
                  
                  const SizedBox(height: 24),
                  // Specs Section
                  const Skeleton(height: 20, width: 150),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Skeleton(height: 14, width: 80),
                          const Skeleton(height: 14, width: 120),
                        ],
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
