import 'package:flutter/material.dart';
import 'package:temo/Home.dart';
import 'package:temo/screens/Product/AddProduct.dart';
import 'package:temo/screens/Product/ProductManager.dart';
import 'package:temo/screens/Setting/ChangeInfomation.dart';
import 'package:temo/screens/Setting/ChangePassword.dart';
import 'package:temo/screens/Setting/Setting.dart';
import 'package:temo/screens/authencation/Sign_up/SignUpStep1Screen.dart';
import 'package:temo/screens/authencation/Sign_up/SignUpStep2PasswordScreen.dart';
import 'package:temo/screens/authencation/Sign_up/SignUpStep3AddressScreen.dart';
import 'package:temo/screens/authencation/get_started_screen.dart';
import '../screens/authencation/Login/signin_screen.dart';
import 'package:temo/screens/Product/SuccessPostScreen.dart';
import 'package:temo/screens/Coin/CoinManagerScreen.dart';
import 'package:temo/screens/Setting/AboutScreen.dart';
import 'package:temo/screens/Product/ProductDetail.dart';


// iOS-style smooth route transition
Route smoothRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var slideTween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

// Helper function for smooth imperative navigation
Future<T?> smoothPush<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    ),
  );
}


Route? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/get_started':
      return smoothRoute(const GetStartedScreen(), settings);
    case '/signin':
      return smoothRoute(const SignInScreen(), settings);

  // ── 3 bước đăng ký mới ──────────────────────────────────────────────
    case '/signup':
      return smoothRoute(const SignUpStep1Screen(), settings);
    case '/signup/password':
      return smoothRoute(const SignUpStep2PasswordScreen(), settings);
    case '/signup/address':
      return smoothRoute(const SignUpStep3AddressScreen(), settings);
  // ─────────────────────────────────────────────────────────────────────

    case '/home':
      return smoothRoute(Home(), settings);
    case '/add_product':
      return smoothRoute(const AddProduct(), settings);
    case '/settings':
      return smoothRoute(Setting(), settings);
    case '/change-infomation':
      return smoothRoute(ChangeInformationScreen(), settings);
    case '/change-password':
      return smoothRoute(ChangePasswordScreen(), settings);
    case '/product-manager':
      return smoothRoute(ProductManager(), settings);
    case '/success_post':
      return smoothRoute(const SuccessPostScreen(), settings);
    case '/coin_manager':
      return smoothRoute(const CoinManagerScreen(), settings);
    case '/about':
      return smoothRoute(const AboutScreen(), settings);
    case '/product_detail':
      final productId = settings.arguments as String? ?? '';
      return smoothRoute(ProductDetail(productId: productId), settings);
    default:
      return null;
  }
}