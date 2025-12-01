import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';

class ProductManager extends StatefulWidget {
  const ProductManager({super.key});

  @override
  State<ProductManager> createState() => _ProductManager();
}

class _ProductManager extends State<ProductManager> {
  final List<String> _tabs = ['Posted', 'Pending', 'Rejected', 'Removed'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const TopBarSecond(title: 'Product Manager'),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.E2Color,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                indicator: BoxDecoration(
                  color: AppColors.ButtonBlackColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'QuickSand',
                ),
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                children: [
                  _buildProductList('Posted'),
                  _buildProductList('Pending'),
                  _buildProductList('Rejected'),
                  _buildProductList('Removed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(String status) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8, // Số lượng item giả định
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildProductCard(index),
        );
      },
    );
  }

  Widget _buildProductCard(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.F6Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://via.placeholder.com/150',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 90, color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pass ghế văn phòng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'QuickSand',
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  'Furniture',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildStatTag(
                      icon: HeroiconsOutline.eye,
                      text: '128',
                      bgColor: const Color(0xFFFFF0E3), // Cam nhạt
                      textColor: const Color(0xFFFF9C54), // Cam đậm
                    ),

                    const SizedBox(width: 8),

                    _buildStatTag(
                      icon: HeroiconsOutline.currencyDollar,
                      text: '17.000.000',
                      bgColor: const Color(0xFFFCEEEB), // Đỏ nhạt
                      textColor: const Color(0xFFE55858), // Đỏ đậm
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                },
                child: const Icon(HeroiconsOutline.ellipsisHorizontal, color: Colors.black, size: 22),
              ),
              const SizedBox(height: 35),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '15 Oct 2025',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    '09:27 PM',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatTag({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}