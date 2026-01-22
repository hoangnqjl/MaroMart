import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/ButtonWithIcon.dart';

class TopBarSecond extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const TopBarSecond({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopBarSecond();

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

class _TopBarSecond extends State<TopBarSecond> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _TopBarAddProduct(),
    );
  }

  Widget _TopBarAddProduct() {
    return ClipRRect(
      // child: BackdropFilter(
      //   filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // Removed opacity for test
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonWithIcon(
                icon: HeroiconsOutline.chevronLeft,
                onPressed: () {
                  Navigator.pop(context);
                },
                size: 38,
                backgroundColor: AppColors.E2Color,
                iconColor: Colors.black,
                isSelected: false,
              ),
              Text(
                widget.title,
                style: const TextStyle(
                    fontFamily: 'QuickSand',
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                ),
              ),
              const SizedBox(width: 38)
            ],
          ),
        ),
      ),
    );
  }
}