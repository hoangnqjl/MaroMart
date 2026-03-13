import 'package:flutter/material.dart';
import 'package:maromart/components/TopBarSecond.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: "Về chúng tôi"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', 
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.auto_awesome, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              "Aura",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Phiên bản 2.0",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "© 2026 Aura Team",
               style: TextStyle(fontWeight: FontWeight.w500),
            ),
             const SizedBox(height: 5),
            Text(
               "Designed for VKU Project",
               style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
