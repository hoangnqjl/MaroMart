import 'package:flutter/material.dart';
import 'package:temo/components/CommonAppBar.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:temo/utils/constants.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../services/review_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();

  User? _user;
  List<Product> _products = [];
  double _rating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      // Fetch user details and their products concurrently
      final responses = await Future.wait([
        _userService.getUserById(widget.userId),
        _productService.getUserProducts(widget.userId, limit: 50),
        _reviewService.getRatingSummary(widget.userId),
      ]);

      setState(() {
        _user = responses[0] as User;
        _products = responses[1] as List<Product>;
        final summary = responses[2] as Map<String, dynamic>;
        _rating = (summary['averageRating'] as num).toDouble();
        _totalReviews = (summary['totalReviews'] as num).toInt();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load user information.";
        _isLoading = false;
      });
    }
  }

  String _getFullUrl(String path) {
    if (path.startsWith('http')) return path;
    const baseUrl = ApiConstants.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBaseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CommonAppBar(title: "Profile", showBackButton: true),
      body: _isLoading
          ? const Center(child: ModernLoader())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // User Info Header
                      SliverToBoxAdapter(
                        child: _buildUserHeader(),
                      ),
                      
                      // Products Title
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Text(
                            "Active Listings (${_products.length})",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: 
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Products Grid
                      if (_products.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                "This user has no active listings.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            itemBuilder: (context, index) {
                              return ProductGridItem(product: _products[index]);
                            },
                            childCount: _products.length,
                          ),
                        ),
                        
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserHeader() {
    if (_user == null) return const SizedBox();
    
    final joinDate = DateFormat('dd/MM/yyyy').format(_user!.createdAt);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[200],
            backgroundImage: (_user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(_getFullUrl(_user!.avatarUrl!))
                : null,
            child: (_user!.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 45, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _user!.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "Joined: $joinDate",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < _rating.round() ? Icons.star_rate_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 22,
                );
              }),
              const SizedBox(width: 8),
              Text(
                "${_rating.toStringAsFixed(1)}/5.0 ($_totalReviews reviews)",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
