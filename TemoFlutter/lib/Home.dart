import 'package:flutter/material.dart';
import 'package:temo/components/BottomNavigation.dart';
import 'package:temo/components/TopBar.dart';
import 'package:temo/screens/Home/HomeScreen.dart';
import 'package:temo/components/AppDrawer.dart';
import 'package:temo/screens/Message/MessageScreen.dart';
import 'package:temo/screens/Setting/Setting.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/screens/Product/ProductManager.dart';
import 'package:temo/Colors/AppColors.dart';

import 'package:temo/components/ModernLoader.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<ProductManagerState> _productManagerKey =
      GlobalKey<ProductManagerState>();
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();

  bool _isUserDataLoaded = false;
  int _currentIndex = 0;
  User? _currentUser;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchAndSaveUserDetails();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketService.connect();
    _socketService.onNewNotification = (data) {
      if (mounted) {
        setState(() {
          _unreadNotifications++;
        });
      }
    };
  }

  Future<void> _fetchAndSaveUserDetails() async {
    final userId = StorageHelper.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/get_started',
          (route) => false,
        );
      }
      return;
    }
    try {
      final detailedUser = await _userService.getUserById(userId);
      await StorageHelper.saveUser(detailedUser);
      if (mounted) {
        setState(() {
          _currentUser = detailedUser;
          _isUserDataLoaded = true;
        });
      }
    } catch (e) {
      final cachedUser = StorageHelper.getUser();
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
          _isUserDataLoaded = true;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    if (index == 3) {
      _homeScaffoldKey.currentState?.openDrawer();
      return;
    }

    if (index == _currentIndex) {
      // RELOAD LOGIC
      if (index == 0) {
        _homeScreenKey.currentState?.reload();
      } else if (index == 3) {
        _productManagerKey.currentState?.reload();
      }
    } else {
      setState(() {
        _currentIndex = index;
        if (index == 1) _unreadNotifications = 0;
      });
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          key: _homeScreenKey,
          user: _currentUser,
          onMenuTap: () => _homeScaffoldKey.currentState?.openDrawer(),
        );
      case 1:
        return ProductManager(key: _productManagerKey);
      case 2:
        return MessageScreen();
      case 3:
        return const Setting();
      default:
        return HomeScreen(
          key: _homeScreenKey,
          user: _currentUser,
          onMenuTap: () => _homeScaffoldKey.currentState?.openDrawer(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserDataLoaded) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: ModernLoader(color: AppColors.primary)),
      );
    }

    return Scaffold(
      key: _homeScaffoldKey,
      drawer: AppDrawer(user: _currentUser),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _getCurrentScreen(),
                ),
              ),
            ),
          ),

          // TopBar Removed for now to avoid overlap
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     color: Colors.white.withOpacity(0.0),
          //     child: SafeArea(
          //       bottom: false,
          //       child: TopBar(
          //         user: _currentUser,
          //       ),
          //     ),
          //   ),
          // ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigation(
              selectedIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              notificationCount: _unreadNotifications,
              onAddPressed: () {
                Navigator.pushNamed(context, '/add_product');
              },
            ),
          ),
        ],
      ),
    );
  }
}
