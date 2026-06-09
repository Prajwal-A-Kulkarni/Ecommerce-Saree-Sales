import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'browse_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'welcome_screen.dart';
import 'logistics_dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BrowseScreen(),
    const CartScreen(),
    const WishlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ZARI & GRACE'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // If staff/admin, show logistics portal entry
            if (provider.isLoggedIn && provider.isStaff)
              IconButton(
                icon: const Icon(Icons.dashboard_customize, color: BoutiqueTheme.accentGold),
                tooltip: 'Logistics Portal',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LogisticsDashboardScreen()),
                  );
                },
              ),
            
            IconButton(
              icon: Icon(
                provider.isLoggedIn ? Icons.logout : Icons.login,
                color: BoutiqueTheme.accentGold,
              ),
              tooltip: provider.isLoggedIn ? 'Logout' : 'Login',
              onPressed: () async {
                if (provider.isLoggedIn) {
                  await provider.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 1.0,
              ),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFF08040C).withOpacity(0.4),
                elevation: 0,
                selectedItemColor: BoutiqueTheme.accentGold,
                unselectedItemColor: BoutiqueTheme.textMuted.withOpacity(0.5),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    activeIcon: Icon(Icons.search_rounded),
                    label: 'Sarees',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      label: Text('${provider.cartCount}'),
                      isLabelVisible: provider.cartCount > 0,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    activeIcon: Badge(
                      label: Text('${provider.cartCount}'),
                      isLabelVisible: provider.cartCount > 0,
                      child: const Icon(Icons.shopping_bag),
                    ),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      label: Text('${provider.wishlist.length}'),
                      isLabelVisible: provider.wishlist.isNotEmpty,
                      child: const Icon(Icons.favorite_outline),
                    ),
                    activeIcon: Badge(
                      label: Text('${provider.wishlist.length}'),
                      isLabelVisible: provider.wishlist.isNotEmpty,
                      child: const Icon(Icons.favorite),
                    ),
                    label: 'Wishlist',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
