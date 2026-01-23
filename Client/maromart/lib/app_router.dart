
import 'package:flutter/material.dart';
import 'package:maromart/Home.dart';
import 'package:maromart/screens/Product/AddProduct.dart';
import 'package:maromart/screens/Product/ProductManager.dart';
import 'package:maromart/screens/Setting/ChangeInfomation.dart';
import 'package:maromart/screens/Setting/ChangePassword.dart';
import 'package:maromart/screens/Setting/Setting.dart';
import 'package:maromart/screens/authencation/get_started_screen.dart';
import '../screens/authencation/Login/signin_screen.dart';
import '../screens/authencation/Sign_up/signup_info_screen.dart';
import '../screens/authencation/Sign_up/signup_password_screen.dart';
import 'package:maromart/screens/Product/SuccessPostScreen.dart';
import 'package:maromart/screens/Coin/CoinManagerScreen.dart';


// iOS-style smooth route transition
Route smoothRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Smooth iOS-style slide from right with fade
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
    case '/signup':
      return smoothRoute(const SignUpInfoScreen(), settings);
    case '/signup/password':
      return smoothRoute(const SignUpPasswordScreen(), settings);
    case '/home':
      return smoothRoute( Home(), settings);
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
    default:
      return null;
  }
}