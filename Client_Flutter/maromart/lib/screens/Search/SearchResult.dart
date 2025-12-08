import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/components/Post.dart'; // Dùng Post để hiển thị đầy đủ thông tin
import 'package:maromart/models/Product/Product.dart';
import 'package:maromart/services/product_service.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;

  const SearchResultScreen({super.key, required this.keyword});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _doSearch();
  }

  Future<void> _doSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _productService.searchProducts(widget.keyword);

      if (mounted) {
        setState(() {
          _products = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(HeroiconsOutline.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search Results",
              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400),
            ),
            Text(
              '"${widget.keyword}"',
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. Trạng thái đang tải
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Trạng thái lỗi
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.exclamationTriangle, size: 48, color: Colors.orange),
            const SizedBox(height: 10),
            Text("Error: $_errorMessage", style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _doSearch, child: const Text("Try Again"))
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.magnifyingGlass, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No products found for "${widget.keyword}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Post(product: _products[index]),
        );
      },
    );
  }
}