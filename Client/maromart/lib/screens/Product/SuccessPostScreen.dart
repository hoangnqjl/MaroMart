import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class SuccessPostScreen extends StatefulWidget {
  const SuccessPostScreen({Key? key}) : super(key: key);

  @override
  State<SuccessPostScreen> createState() => _SuccessPostScreenState();
}

class _SuccessPostScreenState extends State<SuccessPostScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  HeroiconsOutline.checkBadge,
                  color: Colors.green,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Thành Công!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'QuickSand',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sản phẩm của bạn đã được đăng tải.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Về trang chủ", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                       // Navigate to management
                       // Navigator.pushNamed(context, '/manage_products'); // TODO: Add route
                       Navigator.pop(context); 
                    },
                    child: const Text("Quản lý sản phẩm", style: TextStyle(color: Colors.black)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
