import 'package:flutter/material.dart';
import 'package:maromart/components/BottomNavigation.dart';
import 'package:maromart/components/TopBar.dart';
import 'package:maromart/screens/Home/HomeScreen.dart';
import 'package:maromart/screens/Message/MessageScreen.dart';
import 'package:maromart/screens/Notification/NotificationScreen.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/screens/Product/ProductManager.dart';
import 'package:maromart/Colors/AppColors.dart';

import 'package:maromart/components/ModernLoader.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ProductManagerState> _productManagerKey = GlobalKey<ProductManagerState>();

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
        Navigator.pushNamedAndRemoveUntil(context, '/get_started', (route) => false);
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
        return HomeScreen(key: _homeScreenKey, user: _currentUser);
      case 1:
        return NotificationScreen();
      case 2:
        return MessageScreen();
      case 3:
        return ProductManager(key: _productManagerKey);
      default:
        return HomeScreen(key: _homeScreenKey, user: _currentUser);
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
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
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
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        notificationCount: _unreadNotifications,
        onAddPressed: () {
          Navigator.pushNamed(context, '/add_product');
        },
      ),
    );
  }
}

