import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/components/ModernLoader.dart';

class CoinManagerScreen extends StatefulWidget {
  const CoinManagerScreen({super.key});

  @override
  State<CoinManagerScreen> createState() => _CoinManagerScreenState();
}

class _CoinManagerScreenState extends State<CoinManagerScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _depositPackages = [
    {'price': 10000, 'coins': 10},
    {'price': 20000, 'coins': 20},
    {'price': 50000, 'coins': 50},
    {'price': 100000, 'coins': 100},
    {'price': 200000, 'coins': 200},
    {'price': 500000, 'coins': 500},
  ];

  String _formatCurrency(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price).trim();
  }

  Future<void> _handleDeposit(int coins, int price) async {
    setState(() => _isLoading = true);
    
    // Simulate Payment Process
    await Future.delayed(const Duration(seconds: 2));

    try {
      await _userService.depositCoins(coins);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nạp thành công $coins Coins!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDepositSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text("Nạp Coins", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("1 Coin = 1.000đ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _depositPackages.length,
                itemBuilder: (context, index) {
                  final pkg = _depositPackages[index];
                  return GestureDetector(
                    onTap: () => _showPaymentSimulation(context, pkg['coins'], pkg['price']),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[50],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${pkg['coins']} Coins", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F4045))),
                          const SizedBox(height: 4),
                          Text(_formatCurrency(pkg['price']), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSimulation(BuildContext context, int coins, int price) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Xác nhận thanh toán"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(HeroiconsOutline.creditCard, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text("Thanh toán: ${_formatCurrency(price)}"),
                Text("Nhận: $coins Coins"),
                if (_isLoading) ...[
                  const ModernLoader(),
                  const SizedBox(height: 10),
                  const Text("Đang xử lý giao dịch..."),
                ]
              ],
            ),
            actions: _isLoading ? [] : [
              TextButton(child: const Text("Hủy"), onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await Future.delayed(const Duration(seconds: 2)); // Fake processing
                  if (context.mounted) {
                     Navigator.pop(context); // Close dialog
                     _handleDeposit(coins, price);
                  }
                },
                child: const Text("Thanh toán ngay"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ví của tôi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ValueListenableBuilder<User?>(
        valueListenable: _userService.userNotifier,
        builder: (context, user, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3F4045), Color(0xFF1A1A1A)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                    ]
                  ),
                  child: Column(
                    children: [
                      const Text("Số dư hiện tại", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(HeroiconsSolid.currencyDollar, color: Colors.amber, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            "${user?.coins ?? 0}",
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showDepositSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Nạp thêm Coins", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Align(alignment: Alignment.centerLeft, child: Text("Giao dịch gần đây", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(HeroiconsOutline.clock, size: 48, color: Colors.grey[200]),
                        const SizedBox(height: 8),
                        Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
