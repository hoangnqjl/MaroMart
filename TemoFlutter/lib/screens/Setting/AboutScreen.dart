import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/Colors/AppColors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Blur Blobs (Consistent with Home)
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFB7C7F).withOpacity(0.15),
                      const Color(0xFFFB7C7F).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFCC80).withOpacity(0.12),
                      const Color(0xFFFFCC80).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // Space for FloatingHeader
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Hero Image (The Otter)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                'assets/images/version_otter.png',
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/images/logo.png',
                                  width: 120,
                                  height: 120,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // App Name & Version
                          Text(
                            "Temo",
                            style: GoogleFonts.quicksand(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Version 10.0",
                              style: GoogleFonts.quicksand(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Description/Mission
                          Text(
                            "Temo là nền tảng kết nối cộng đồng mua bán thông minh, mang lại trải nghiệm an toàn và thân thiện nhất cho mọi người.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Absolute Bottom Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "© 2026 Temo Team",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
                fontSize: 14,
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: FloatingHeader(
                title: "About Us",
                hasBackground: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
