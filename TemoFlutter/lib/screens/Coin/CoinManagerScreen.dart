import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/user_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/screens/Coin/BankTransferScreen.dart';
import 'package:temo/app_router.dart';

import '../../components/TopBarCustom.dart';

class CoinManagerScreen extends StatefulWidget {
  const CoinManagerScreen({super.key});

  @override
  State<CoinManagerScreen> createState() => _CoinManagerScreenState();
}

class _CoinManagerScreenState extends State<CoinManagerScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  List<dynamic> _history = [];
  bool _isHistoryLoading = false;

  final List<Map<String, dynamic>> _coinPackages = [
    {'coins': 50, 'price': 10000, 'priceText': '10,000 đ', 'bonus': 0},
    {'coins': 100, 'price': 20000, 'priceText': '20,000 đ', 'bonus': 5},
    {'coins': 500, 'price': 100000, 'priceText': '100,000 đ', 'bonus': 50},
    {'coins': 1000, 'price': 200000, 'priceText': '200,000 đ', 'bonus': 120},
  ];

  final List<Map<String, dynamic>> _banks = [
    {'id': 'mbb', 'name': 'MB Bank', 'bin': '970422', 'accountNo': '0000 1234 5678', 'accountHolder': 'TEMO CORP', 'logo': 'assets/images/mbb_logo.png', 'color': const Color(0xFF003DA5)},
    {'id': 'vcb', 'name': 'Vietcombank', 'bin': '970436', 'accountNo': '0071 0000 1234 5', 'accountHolder': 'TEMO CORP', 'logo': 'assets/images/vcb_logo.png', 'color': const Color(0xFF00B14F)},
    {'id': 'tcb', 'name': 'Techcombank', 'bin': '970407', 'accountNo': '1903 1234 5678 01', 'accountHolder': 'TEMO CORP', 'logo': 'assets/images/tcb_logo.png', 'color': const Color(0xFFE01E26)},
    {'id': 'vpb', 'name': 'VPBank', 'bin': '970432', 'accountNo': '1234 5678 90', 'accountHolder': 'TEMO CORP', 'logo': 'assets/images/vpb_logo.png', 'color': const Color(0xFF009149)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (mounted) setState(() => _isHistoryLoading = true);
    try {
      final history = await _userService.getTransactionHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  void _showBankSelection(Map<String, dynamic> pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text("Chọn Ngân hàng", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Vui lòng chọn ngân hàng bạn muốn chuyển khoản", style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _banks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bank = _banks[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final success = await smoothPush(
                          context,
                          BankTransferScreen(
                            bank: bank,
                            coins: pkg['coins'],
                            bonus: pkg['bonus'],
                            priceText: pkg['priceText'],
                            amount: pkg['price'].toDouble(),
                          ),
                        );
                        if (success == true) _fetchHistory();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: bank['color'].withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.account_balance, color: bank['color'], size: 20),
                            ),
                            const SizedBox(width: 16),
                            Text(bank['name'], style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -50, left: 0, right: 0, height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFFFD09F).withOpacity(0.8), const Color(0xFFFFD09F).withOpacity(0)],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: TopBarCustom(title: "Ví Temo (Xu)")),
                
                // Balance Card
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<User?>(
                    valueListenable: _userService.userNotifier,
                    builder: (context, user, child) {
                      final currentCoins = user?.coins?.toInt() ?? 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Số dư hiện tại", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600, fontFamily: 'Quicksand')),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text("$currentCoins", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Quicksand', color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    const Icon(HeroiconsSolid.currencyDollar, color: Colors.amber, size: 32),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(HeroiconsOutline.wallet, color: AppColors.primary, size: 32),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Select Packages Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Chọn gói nạp Xu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pkg = _coinPackages[index];
                        return GestureDetector(
                          onTap: () => _showBankSelection(pkg),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${pkg['coins']} Xu", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                                if (pkg['bonus'] > 0)
                                  Text("+${pkg['bonus']} Xu thưởng", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                                const SizedBox(height: 4),
                                Text(pkg['priceText'], style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Quicksand')),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _coinPackages.length,
                    ),
                  ),
                ),

                // History Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 10),
                    child: Text("Giao dịch gần đây", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                  ),
                ),

                if (_isHistoryLoading)
                  const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: ModernLoader())))
                else if (_history.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(HeroiconsOutline.clock, size: 48, color: Colors.grey[200]),
                            const SizedBox(height: 8),
                            const Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey, fontFamily: 'Quicksand')),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = _history[index];
                        final isDeposit = tx['type'] == 'DEPOSIT';
                        final date = DateTime.parse(tx['createdAt']).toLocal();
                        final formattedDate = "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(isDeposit ? HeroiconsOutline.arrowDownLeft : HeroiconsOutline.rocketLaunch, 
                                   color: isDeposit ? Colors.green : Colors.red, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isDeposit ? "Nạp Xu vào ví" : "Đẩy tin sản phẩm", style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                                    Text(formattedDate, style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Quicksand')),
                                  ],
                                ),
                              ),
                              Text("${isDeposit ? '+' : '-'}${tx['amount']} Xu", 
                                   style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.red, fontFamily: 'Quicksand')),
                            ],
                          ),
                        );
                      },
                      childCount: _history.length,
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),

          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const Center(child: ModernLoader()),
            ),
        ],
      ),
    );
  }
}
