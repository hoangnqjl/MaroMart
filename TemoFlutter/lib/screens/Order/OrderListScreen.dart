import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/TopBarCustom.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/services/order_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'RatingScreen.dart';

class OrderListScreen extends StatefulWidget {
  final int initialTab;
  const OrderListScreen({super.key, this.initialTab = 0});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  List<dynamic> _buyOrders = [];
  List<dynamic> _sellOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await _orderService.getMyOrders();
      setState(() {
        _buyOrders = data['buyOrders'] ?? [];
        _sellOrders = data['sellOrders'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToOrder(String orderId, String status) async {
    try {
      await _orderService.respondToRequest(orderId, status);
      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'accepted' ? "Đã chấp nhận yêu cầu" : "Đã từ chối yêu cầu"),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            FloatingHeader(
              title: "Quản lý đơn hàng",
              hasBackground: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Đơn mua"),
                  Tab(text: "Đơn bán"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading 
                ? const Center(child: ModernLoader())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(_buyOrders, isBuy: true),
                      _buildOrderList(_sellOrders, isBuy: false),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required bool isBuy}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(HeroiconsOutline.shoppingCart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Không tìm thấy đơn hàng nào", style: TextStyle(color: Colors.grey[400], fontFamily: 'Quicksand')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = order['status'];
        final isPending = status == 'pending';
        final isAccepted = status == 'accepted';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ID: ${order['id'].substring(0, 8)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(HeroiconsOutline.shoppingBag, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['product']?['productName'] ?? "Sản phẩm không xác định",
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (!isBuy)
                          Text(
                            "Được yêu cầu bởi: ${order['buyer']?['fullName'] ?? 'Người dùng'}",
                            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600]),
                          )
                        else
                          Text(
                            "Người bán: ${order['seller']?['fullName'] ?? 'MaroMart'}",
                            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Yêu cầu giao dịch sản phẩm", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              if (!isBuy && isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToOrder(order['id'], 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Từ chối", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToOrder(order['id'], 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Chấp nhận", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              if (isBuy && isAccepted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RatingScreen(
                            orderId: order['id'],
                            revieweeId: order['sellerId'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Đánh giá người bán", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending': color = Colors.orange; text = "Chờ duyệt"; break;
      case 'accepted': color = Colors.green; text = "Đã chấp nhận"; break;
      case 'rejected': color = Colors.red; text = "Đã từ chối"; break;
      case 'completed': color = Colors.blue; text = "Hoàn tất"; break;
      default: color = Colors.grey; text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
