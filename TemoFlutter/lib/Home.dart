import 'package:flutter/material.dart';
import 'package:temo/components/BottomNavigation.dart';
import 'package:temo/components/TopBar.dart';
import 'package:temo/screens/Home/HomeScreen.dart';

import 'package:temo/screens/Message/MessageScreen.dart';
import 'package:temo/screens/Setting/Setting.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/screens/Product/ProductManager.dart';
import 'package:temo/Colors/AppColors.dart';

import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/SideMenu.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<ProductManagerState> _productManagerKey =
      GlobalKey<ProductManagerState>();
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();

  bool _isUserDataLoaded = false;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  User? _currentUser;
  int _unreadNotifications = 0;

  // Animation for Threads-style drawer
  AnimationController? _animationController;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fetchAndSaveUserDetails();
    _initSocketListeners();
  }

  void _toggleDrawer() {
    if (_animationController == null) return;
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _animationController!.forward();
      } else {
        _animationController!.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _pageController.dispose();
    super.dispose();
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
    if (_isDrawerOpen) {
      _toggleDrawer();
      return;
    }
    if (index == _currentIndex) {
      // RELOAD LOGIC
      if (index == 0) {
        _homeScreenKey.currentState?.reload();
      } else if (index == 1) {
        _productManagerKey.currentState?.reload();
      }
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserDataLoaded || _animationController == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: ModernLoader(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Lower Layer: Side Menu
          SideMenu(
            user: _currentUser,
            onNavigate: (page) {
              _toggleDrawer();
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
          ),

          // Upper Layer: Main Content
          AnimatedBuilder(
            animation: _animationController!,
            builder: (context, child) {
              final animValue = CurvedAnimation(
                parent: _animationController!,
                curve: Curves.easeInOutQuart,
              ).value;
              double slide = 240.0 * animValue;
              double scale = 1.0 - (0.15 * animValue);
              double radius = 28.0 * animValue;

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _isDrawerOpen ? _toggleDrawer : null,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (_isDrawerOpen)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(-10, 0),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: RepaintBoundary(child: child),
                    ),
                  ),
                ),
              );
            },
            child: Scaffold(
              key: _homeScaffoldKey,
              backgroundColor: Colors.white,
              extendBody: true,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: PageView(
                      controller: _pageController,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          if (index == 2) _unreadNotifications = 0;
                        });
                      },
                      children: [
                        HomeScreen(
                          key: _homeScreenKey,
                          user: _currentUser,
                          onMenuTap: _toggleDrawer,
                        ),
                        ProductManager(
                          key: _productManagerKey,
                          onMenuTap: _toggleDrawer,
                        ),
                        MessageScreen(
                          onMenuTap: _toggleDrawer,
                        ),
                        Setting(
                          onMenuTap: _toggleDrawer,
                        ),
                      ],
                    ),
                  ),
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
          ),
        ],
      ),
    );
  }
}
