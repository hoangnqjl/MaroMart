import 'package:flutter/material.dart';
import 'package:maromart/components/BottomNavigation.dart';
import 'package:maromart/components/SearchItem.dart';
import 'package:maromart/components/TopBar.dart';
import 'package:maromart/screens/Home/HomeScreen.dart';
import 'package:maromart/screens/Message/MessageScreen.dart';
import 'package:maromart/screens/Notification/NotificationScreen.dart';
import 'package:maromart/screens/Search/SearchScreen.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/screens/Product/ProductManager.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

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
      print("Home received notification: $data");
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
        Future.delayed(Duration.zero, () {
          Navigator.pushNamedAndRemoveUntil(context, '/get_started', (route) => false);
        });
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
    setState(() {
      _currentIndex = index;

      if (index == 1) {
        _unreadNotifications = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserDataLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      HomeScreen(key: _homeScreenKey),
      NotificationScreen(),
      MessageScreen(),
      ProductManager(), // Changed from SearchScreen to ProductManager as requested (Cube icon)
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: TopBar(
                user: _currentUser,
                onFilterSelected: (categoryId, province, ward) {
                  if (_currentIndex == 0) {
                    _homeScreenKey.currentState?.updateFilter(
                        categoryId: categoryId,
                        province: province,
                        ward: ward
                    );
                  } else {
                    setState(() => _currentIndex = 0);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _homeScreenKey.currentState?.updateFilter(
                          categoryId: categoryId,
                          province: province,
                          ward: ward
                      );
                    });
                  }
                },
              ),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                screens[_currentIndex],

                // Removed SearchItem logic as tab 3 is now Manager
                
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
          ),
        ],
      ),
    );
  }
}
