import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZARI & GRACE'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: BoutiqueTheme.primaryBg,
        selectedItemColor: BoutiqueTheme.accentGold,
        unselectedItemColor: BoutiqueTheme.textMuted.withOpacity(0.6),
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
    );
  }
}
