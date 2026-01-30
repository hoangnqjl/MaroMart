import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:maromart/Home.dart';
import 'package:maromart/screens/authencation/get_started_screen.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:provider/provider.dart';
import 'package:maromart/providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maromart/l10n/app_localizations.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await StorageHelper.init().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint("Storage initialization timed out. Proceeding regardless.");
      },
    );
  } catch (e) {
    debugPrint("Storage initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'MaroMart',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('vi'), // Vietnamese
            ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
        useMaterial3: true,
        fontFamily: 'QuickSand',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all(false),
          thickness: MaterialStateProperty.all(4),
          radius: const Radius.circular(4),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamily: 'QuickSand',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
            home: StorageHelper.isLoggedIn() ? Home() : const GetStartedScreen(),
            onGenerateRoute: onGenerateRoute,
          );
        },
      ),
    );
  }
}