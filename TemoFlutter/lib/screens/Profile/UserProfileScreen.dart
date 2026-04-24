import 'package:flutter/material.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/ProductGridItem.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/product_service.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/services/order_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:temo/utils/constants.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';

import '../../services/review_service.dart';
import 'package:temo/screens/Common/BugReportScreen.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();
  final OrderService _orderService = OrderService();

  User? _user;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<dynamic> _reviews = [];
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  
  double _rating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _canReview = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      
      final responses = await Future.wait([
        _userService.getUserById(widget.userId),
        _productService.getUserProducts(widget.userId, limit: 100),
        _reviewService.getRatingSummary(widget.userId),
        _reviewService.getUserReviews(widget.userId),
        _productService.getCategories(),
        _orderService.getMyOrders(),
      ]);

      _user = responses[0] as User;
      _allProducts = responses[1] as List<Product>;
      _filteredProducts = _allProducts;
      
      final summary = responses[2] as Map<String, dynamic>;
      _rating = (summary['averageRating'] as num).toDouble();
      _totalReviews = (summary['totalReviews'] as num).toInt();
      
      _reviews = responses[3] as List<dynamic>;
      _categories = responses[4] as List<dynamic>;

      // Check if user has bought from this person
      final ordersResponse = responses[5] as Map<String, dynamic>;
      if (ordersResponse['success'] == true && ordersResponse['orders'] != null) {
        final List orders = ordersResponse['orders'];
        _canReview = orders.any((o) => o['sellerId'] == widget.userId && o['status'] == 'COMPLETED');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể tải thông tin người dùng.";
        _isLoading = false;
      });
    }
  }

  void _handleReview() {
    if (_canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tính năng gửi đánh giá đang được mở...")),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text("Thông báo", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Text("Bạn chưa mua hàng từ người dùng này nên chưa thể đánh giá.", style: GoogleFonts.roboto()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    }
  }

  void _filterProducts(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == null || categoryId.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) => p.categoryId == categoryId).toList();
      }
    });
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
    if (_isLoading) return const Scaffold(body: Center(child: ModernLoader()));
    if (_errorMessage != null) return Scaffold(body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))));

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(HeroiconsOutline.chevronLeft, color: Colors.black, size: 20),
                  ),
                ),
              ),

              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingHeader.buildActionBubble(
                    icon: HeroiconsSolid.ellipsisHorizontal,
                    onTap: () => UIHelper.showOptionsMenu(context, screenName: "Trang cá nhân của ${_user?.fullName}"),
                  ),
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  var top = constraints.biggest.height;
                  var opacity = (top - kToolbarHeight) / (300 - kToolbarHeight);
                  opacity = opacity.clamp(0.0, 1.0);
                  
                  return FlexibleSpaceBar(
                    centerTitle: true,
                    title: opacity < 0.2 
                      ? Text(
                          _user?.fullName ?? "",
                          style: GoogleFonts.roboto(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900),
                        ) 
                      : null,
                    background: Stack(
                      children: [
                        // Cover Image with extreme bottom curve
                        Positioned.fill(
                          bottom: 50,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(60),
                              bottomRight: Radius.circular(60),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: "https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=2070&auto=format&fit=crop",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Avatar Overlap - Fades out
                        Opacity(
                          opacity: opacity,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                                  ],
                                  image: DecorationImage(
                                    image: (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                                        ? CachedNetworkImageProvider(_getFullUrl(_user!.avatarUrl!))
                                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _user?.fullName ?? "Người dùng",
                    style: GoogleFonts.roboto(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: const Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@${_user?.fullName.replaceAll(' ', '').toLowerCase() ?? 'user'}",
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 28),
                  // STATS ROW
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: _buildStatItem("Sản phẩm", _allProducts.length.toString())),
                        _buildVerticalDivider(),
                        Expanded(child: _buildStatItem("Đánh giá", _rating.toStringAsFixed(1))),
                        _buildVerticalDivider(),
                        Expanded(child: _buildStatItem("Tham gia", DateFormat('MM/yy').format(_user?.createdAt ?? DateTime.now()))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ACTION BUTTONS - High Border Radius
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text("Đánh giá người dùng", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                foregroundColor: const Color(0xFF1F2937),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text("Nhắn tin", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w800),
                  tabs: [
                    Tab(text: "Sản phẩm (${_allProducts.length})"),
                    Tab(text: "Đánh giá ($_totalReviews)"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 25,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey[200],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildProductsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildCategoryFilter()),
        if (_filteredProducts.isEmpty)
          const SliverFillRemaining(child: Center(child: Text("Không có sản phẩm nào.")))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemBuilder: (context, index) => ProductGridItem(product: _filteredProducts[index]),
              childCount: _filteredProducts.length,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip("Tất cả", null),
          ..._categories.map((cat) => _buildFilterChip(cat['categoryName'], cat['categoryId'])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? id) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _filterProducts(id),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF4B5563)),
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildRatingSummaryCard(),
        const SizedBox(height: 24),
        if (_reviews.isEmpty) const Center(child: Text("Chưa có đánh giá nào.")) else ..._reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: const Color(0xFFF3F4F6))
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_rating.toStringAsFixed(1), style: GoogleFonts.roboto(fontSize: 40, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < _rating.round() ? Colors.amber : Colors.grey[300], size: 20))),
              const SizedBox(height: 4),
              Text("$_totalReviews đánh giá", style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [_buildRatingBar(5, 0.8), _buildRatingBar(4, 0.1), _buildRatingBar(3, 0.05), _buildRatingBar(2, 0.02), _buildRatingBar(1, 0.03)],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percent) {
    return Row(
      children: [
        Text(stars.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Container(
          width: 80, height: 6,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: percent, child: Container(decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(3)))),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final reviewerName = review['reviewer']?['fullName'] ?? "Người dùng";
    final reviewerAvatar = review['reviewer']?['avatarUrl'];
    final rating = (review['rating'] as num).toInt();
    final comment = review['comment'] ?? "";
    final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(review['createdAt']));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22, backgroundColor: Colors.grey[100],
            backgroundImage: (reviewerAvatar != null) ? CachedNetworkImageProvider(_getFullUrl(reviewerAvatar)) : null,
            child: (reviewerAvatar == null) ? const Icon(Icons.person, size: 22, color: Colors.grey) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reviewerName, style: GoogleFonts.roboto(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(date, style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < rating ? Colors.amber : Colors.grey[200], size: 16))),
                const SizedBox(height: 10),
                Text(comment, style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF4B5563), height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
