
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


Route smoothRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
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
    default:
      return null;
  }
}