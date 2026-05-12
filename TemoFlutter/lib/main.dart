import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:temo/Home.dart';
import 'package:temo/screens/authencation/get_started_screen.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:provider/provider.dart';
import 'package:temo/providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:temo/l10n/app_localizations.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/screens/splash/video_splash_screen.dart';
import 'package:flutter/services.dart';
import 'app_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge mode for a premium, immersive look
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
            title: 'Temo',
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
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.background,
              useMaterial3: true,
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
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                titleTextStyle: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
                contentTextStyle: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: const Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                },
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF1E1E1E),
                surfaceTintColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                titleTextStyle: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                contentTextStyle: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: const Color(0xFF1E1E1E),
                surfaceTintColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),
            home: const VideoSplashScreen(),
            onGenerateRoute: onGenerateRoute,
          );
        },
      ),
    );
  }
}
