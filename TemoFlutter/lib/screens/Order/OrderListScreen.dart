import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/TopBarCustom.dart';
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
        content: Text(status == 'accepted' ? "Request accepted" : "Request rejected"),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            TopBarCustom(title: "Order Management"),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: "Buy Orders"),
                Tab(text: "Sell Orders"),
              ],
            ),
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
            Text("No orders found", style: TextStyle(color: Colors.grey[400], fontFamily: 'Quicksand')),
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ID: ${order['id'].substring(0, 8)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Product Transaction Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Quicksand')),
              const SizedBox(height: 16),
              if (!isBuy && isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToOrder(order['id'], 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToOrder(order['id'], 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Accept", style: TextStyle(color: Colors.white)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Rate Seller", style: TextStyle(color: Colors.white)),
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
      case 'pending': color = Colors.orange; text = "Pending"; break;
      case 'accepted': color = Colors.green; text = "Accepted"; break;
      case 'rejected': color = Colors.red; text = "Rejected"; break;
      case 'completed': color = Colors.blue; text = "Completed"; break;
      default: color = Colors.grey; text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
