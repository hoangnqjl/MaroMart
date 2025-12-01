import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/ButtonWithIcon.dart';
import 'package:maromart/components/VideoPlayerWidget.dart';
import 'package:maromart/models/Media/MediaItem.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart'; // Import ProductService
import 'package:intl/intl.dart';

class ProductDetail extends StatefulWidget {
  final String productId;

  const ProductDetail({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => ProductDetailState();
}

class ProductDetailState extends State<ProductDetail> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoading = true;
  bool isDescription = true;
  int currentPage = 0;
  late PageController _pageController;

  List<MediaItem> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchProductDetail();
  }

  Future<void> _fetchProductDetail() async {
    try {
      final product = await _productService.getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _mediaItems = _parseProductMedia(product.productMedia);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải chi tiết sản phẩm: ${e.toString()}')),
        );
      }
      print('Lỗi tải chi tiết sản phẩm: $e');
    }
  }

  List<MediaItem> _parseProductMedia(List<String> rawMedia) {
    return rawMedia.map((mediaString) {
      final parts = mediaString.split(':');
      final type = parts.first.toLowerCase();
      final url = parts.length > 1 ? parts.sublist(1).join(':').trim() : mediaString.trim();

      if (type == 'video') {
        return MediaItem(type: MediaType.video, url: url);
      } else {
        return MediaItem(type: MediaType.image, url: url);
      }
    }).toList();
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} VND';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy thông tin sản phẩm.')),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.66,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemCount: _mediaItems.length,
                        itemBuilder: (context, index) {
                          return _buildMediaItem(_mediaItems[index]);
                        },
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _mediaItems.length,
                                (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productCategory.toUpperCase(), // Category
                                style: const TextStyle(
                                  fontWeight: FontWeight.w100,
                                  fontSize: 8,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.productName, // Tên sản phẩm
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatPrice(product.productPrice), // Giá
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildTabToggle(),

                      const SizedBox(height: 16),

                      // Nội dung Tab
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        child: isDescription
                            ? _buildDescriptionContent(product.productDescription)
                            : _buildViewDetailContent(product.productAttribute, product),
                      ),

                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(HeroiconsOutline.arrowLeft, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(HeroiconsSolid.heart, color: Colors.red, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lấy chiều rộng tổng của cha trừ đi padding (4px: 2 trái + 2 phải)
        final double totalWidth = constraints.maxWidth;
        final double tabWidth = (totalWidth - 4) / 2;

        return Container(
          height: 42,
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: AppColors.E2Color,
          ),
          child: Stack(
            children: [
              // 1. THANH TRƯỢT MÀU ĐEN (Background động)
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                // Nếu đang ở Description thì nằm trái (-1), View Detail thì nằm phải (1)
                alignment: isDescription ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: tabWidth, // Chiều rộng động = 50% cha
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              // 2. TEXT BUTTONS (Nằm đè lên trên)
              Row(
                children: [
                  _buildTabItem(
                    title: 'Description',
                    isSelected: isDescription,
                    onTap: () => setState(() => isDescription = true),
                  ),
                  _buildTabItem(
                    title: 'View Detail',
                    isSelected: !isDescription,
                    onTap: () => setState(() => isDescription = false),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // Đổi màu chữ tương phản với nền đen/xám
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => print('Chat pressed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(HeroiconsOutline.chatBubbleOvalLeft, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: () => print('Call pressed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(HeroiconsSolid.phone, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Call now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    if (item.type == MediaType.image) {
      return Image.network(
        item.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
            ),
          );
        },
      );
    } else {
      return VideoPlayerWidget(videoUrl: item.url);
    }
  }

  // Widget hiển thị Mô tả
  Widget _buildDescriptionContent(String description) {
    return Container(
      key: const ValueKey('description'),
      width: double.infinity,
      child: Text(
        description, // Dùng mô tả từ API
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildViewDetailContent(dynamic attributesInput, Product product) {
    final List<Map<String, String>> displayList = [
      {'label': 'Thương hiệu', 'value': product.productBrand},
      {'label': 'Tình trạng', 'value': product.productCondition},
      {'label': 'Xuất xứ', 'value': product.productOrigin},
      {'label': 'Bảo hành', 'value': product.productWP},
    ];
    if (product.productAddress != null) {
      if (product.productAddress!.province.isNotEmpty) {
        displayList.add({'label': 'Khu vực', 'value': product.productAddress!.province});
      }
      if (product.productAddress!.commute.isNotEmpty) {
        displayList.add({'label': 'Phường/Xã', 'value': product.productAddress!.commute});
      }
      if (product.productAddress!.detail.isNotEmpty) {
        displayList.add({'label': 'Địa chỉ', 'value': product.productAddress!.detail});
      }
    }
    if (attributesInput != null) {
      Map<String, dynamic> attrMap = {};

      try {
        if (attributesInput is String) {
          attrMap = jsonDecode(attributesInput);
        } else if (attributesInput is Map) {
          attrMap = Map<String, dynamic>.from(attributesInput);
        } else if (attributesInput is ProductAttribute) {
          // Trường hợp 3: Dữ liệu là Model cũ (Fallback cho dữ liệu cũ)
          if (attributesInput.cpu != null) attrMap['CPU'] = attributesInput.cpu;
          if (attributesInput.ram != null) attrMap['RAM'] = attributesInput.ram;
          if (attributesInput.storage != null) attrMap['Storage'] = attributesInput.storage;
          if (attributesInput.screen != null) attrMap['Screen'] = attributesInput.screen;
        }
      } catch (e) {
        print("Lỗi parse attribute: $e");
      }

      attrMap.forEach((key, value) {
        if (value.toString().isNotEmpty) {
          displayList.add({'label': key, 'value': value.toString()});
        }
      });
    }

    return Container(
        key: const ValueKey('detail'),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: displayList.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detail['label']!,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                Text(
                  detail['value']!,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          )).toList(),
        )
    );
  }
}