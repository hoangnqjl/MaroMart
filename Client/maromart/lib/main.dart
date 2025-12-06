import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:maromart/Home.dart';
import 'package:maromart/screens/authencation/get_started_screen.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/utils/storage.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageHelper.init();
  // if (StorageHelper.isLoggedIn()) {
  //   SocketService().connect();
  // }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaroMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'QuickSand',
        // iOS-style page transitions for all platforms
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        // Smooth scroll physics
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all(false),
          thickness: MaterialStateProperty.all(4),
          radius: const Radius.circular(4),
        ),
      ),
      // Custom smooth scroll behavior
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      home: StorageHelper.isLoggedIn() ? Home() : const GetStartedScreen(),
      onGenerateRoute: onGenerateRoute,
    );
  }
}